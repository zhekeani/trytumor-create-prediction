# Enable the used APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "secretmanager.googleapis.com",
    "iam.googleapis.com"
  ]
}

locals {
  sa_id_template           = "${var.environment.prefix}-sa-%s"
  sa_display_name_template = "Service Account - ${var.environment.type} %s"
}


locals {
  service_accounts = {
    fastapi_webhook = {
      account_id   = format(local.sa_id_template, "fastapi-webhook")
      display_name = format(local.sa_display_name_template, "FastAPI webhook")
    }
    cloud_fn = {
      account_id   = format(local.sa_id_template, "cloud-fn")
      display_name = format(local.sa_display_name_template, "Cloud function")
    }
  }
}

# Create the service accounts
resource "google_service_account" "trytumor_cp" {
  for_each = local.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name

  depends_on = [module.project-services]
}

# Generate service account key
resource "google_service_account_key" "trytumor_cp" {
  for_each = google_service_account.trytumor_cp

  service_account_id = each.value.name

  depends_on = [google_service_account.trytumor_cp]
}

