data "google_project" "current" {}

# Enable Cloud Run API
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = data.google_project.current.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "run.googleapis.com"
  ]
}

locals {
  app_service_name = "fastapi-web-server"
}

# Create the Cloud Run service
resource "google_cloud_run_service" "run_service" {
  name     = local.app_service_name
  location = var.location

  template {
    spec {
      containers {
        image = var.docker_image_url
        env {
          name  = "JWT_CONFIG"
          value = var.jwt_config
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
}

output "service_url" {
  value       = google_cloud_run_service.run_service.status[0].url
  description = "Cloud Run server URL."
}