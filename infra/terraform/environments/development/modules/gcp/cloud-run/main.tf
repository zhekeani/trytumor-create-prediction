# Enable Cloud Run API
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "run.googleapis.com"
  ]
}

# Create the Cloud Run service
resource "google_cloud_run_service" "run_service" {
  name     = var.app_service_name
  location = var.location

  template {
    spec {
      containers {
        image = var.docker_image_url
        ports {
          container_port = var.container_port
        }
        env {
          name  = "PROJECT_ID"
          value = var.env.project_id
        }
        env {
          name  = "SERVICE_ACCOUNT_KEY"
          value = var.env.service_account_key
        }
        env {
          name  = "BUCKET_NAME"
          value = var.env.bucket_name
        }
        env {
          name  = "JWT_SECRET"
          value = var.env.jwt_secret
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "2048Mi"
          }
          requests = {
            cpu    = "1"
            memory = "2048Mi"
          }
        }
      }
      container_concurrency = 1
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Waits for the Cloud Run API to be enabled
  depends_on = [module.project-services]
}

# Allow unauthenticated users to invoke the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloud_run_service.run_service]
}
