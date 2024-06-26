# Enable Cloud Run API
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "run.googleapis.com",
    "storage-api.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

locals {
  project        = var.project_id
  fn_name        = "http-cloud-function-v2"
  fn_desc        = "Cloud function gen2 triggered manually"
  fn_entry_point = "handlePostRequest"
}


resource "google_cloudfunctions2_function" "function" {
  name        = local.fn_name
  location    = var.location
  description = local.fn_desc

  build_config {
    runtime     = "nodejs20"
    entry_point = local.fn_entry_point
    source {
      storage_source {
        bucket = var.storage_bucket_name
        object = var.cloud_fn_zip_path
      }
    }
  }

  service_config {
    max_instance_count             = 1
    available_memory               = "256M"
    timeout_seconds                = 60
    all_traffic_on_latest_revision = true
    service_account_email          = var.service_account_email

    secret_environment_variables {
      key        = "JWT_SECRET"
      project_id = var.project_id
      secret     = var.secrets_id.jwt_secret
      version    = "latest"
    }

    secret_environment_variables {
      key        = "WEBHOOK_TOPIC_ID"
      project_id = var.project_id
      secret     = var.secrets_id.webhook_topic_id
      version    = "latest"
    }
  }

  depends_on = [
    module.project-services
  ]
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloudfunctions2_function.function]
}

