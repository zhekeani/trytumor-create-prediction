# Enable the used APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "iam.googleapis.com",
  ]
}

module "ar_reader_project_iam_bindings" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 7.7"

  projects = [var.project_id]

  bindings = {
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:${var.sa_emails.cloud_fn}"
    ]

    "roles/cloudfunctions.developer" = [
      "serviceAccount:${var.sa_emails.cloud_fn}"
    ]

    "roles/cloudfunctions.serviceAgent" = [
      "serviceAccount:${var.sa_emails.cloud_fn}"
    ]

    "roles/cloudbuild.builds.builder" = [
      "serviceAccount:${var.sa_emails.cloud_fn}"
    ]

    "roles/pubsub.publisher" = [
      "serviceAccount:${var.sa_emails.cloud_fn}",
      "serviceAccount:${var.sa_emails.fastapi_webhook}"
    ]
  }

  depends_on = [module.project-services]
}

module "storage_buckets_iam_bindings" {
  source          = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
  mode            = "additive"
  storage_buckets = var.storage_buckets

  bindings = {
    "roles/storage.objectAdmin" = [
      "serviceAccount:${var.sa_emails.fastapi_webhook}"
    ]
  }

  depends_on = [module.project-services]
}