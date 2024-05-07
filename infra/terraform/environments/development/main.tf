data "google_project" "current" {}

locals {
  environment = {
    type   = "development"
    prefix = "dev"
  }
  project_name        = "${data.google_project.current.name}-cp"
  region              = "asia-southeast2"
  storage_bucket_name = "zhekeani-${data.google_project.current.project_id}"
}

# Create Artifact Registry repositories
module "artifact_registry" {
  source            = "./modules/gcp/artifact-registry"
  location          = local.region
  environment       = local.environment
  repositories_name = ["create-prediction"]
}

# Create Cloud Run