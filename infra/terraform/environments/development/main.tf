data "google_project" "current" {}

locals {
  environment = {
    type   = "development"
    prefix = "dev"
  }
  project_name        = "${data.google_project.current.name}-cp"
  region              = "asia-southeast2"
  storage_bucket_name = var.trytumor_bucket_name
}


# ----------------------------------------------------------------------------------- #
# Service account
module "service_account" {
  source       = "./modules/gcp/service-account"
  environment  = local.environment
  location     = local.region
  project_name = local.project_name
  project_id   = data.google_project.current.project_id
}


locals {
  service_accounts_email = {
    for service_account, sa_obj in module.service_account.sa_obj :
    service_account => sa_obj.email
  }
}

module "service_account_iam" {
  source          = "./modules/gcp/service-account/iam"
  project_id      = data.google_project.current.project_id
  sa_emails       = local.service_accounts_email
  storage_buckets = [local.storage_bucket_name]

  depends_on = [module.service_account]
}


# ----------------------------------------------------------------------------------- #
# Artifact Registry
module "artifact_registry" {
  source            = "./modules/gcp/artifact-registry"
  location          = local.region
  environment       = local.environment
  repositories_name = ["create-prediction"]
}

# ----------------------------------------------------------------------------------- #
# Secret Manager