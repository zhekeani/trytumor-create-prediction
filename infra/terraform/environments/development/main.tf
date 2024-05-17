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
# Cloud Run
locals {
  jwt_secret_version_id = "dev-config-jwt-secret"
}

data "google_secret_manager_secret_version" "jwt_secret" {
  secret = local.jwt_secret_version_id
}

locals {
  webhook_docker_repo  = module.artifact_registry.repositories_url["create-prediction"]
  webhook_docker_image = "dev-trytumor-create-prediction"
  webhook_docker_tag   = "v0.0.1"
  webhook_docker_url   = "${local.webhook_docker_repo}/${local.webhook_docker_image}:${local.webhook_docker_tag}"

  webhook_service_name   = "trytumor-fastapi-webhook"
  webhook_container_port = 8080
  webhook_env = {
    project_id          = data.google_project.current.project_id
    service_account_key = module.service_account.sa_private_keys.fastapi_webhook
    bucket_name         = local.storage_bucket_name
    jwt_secret          = data.google_secret_manager_secret_version.jwt_secret.secret_data
  }
}

module "cloud_run" {
  source           = "./modules/gcp/cloud-run"
  project_id       = data.google_project.current.project_id
  location         = local.region
  docker_image_url = local.webhook_docker_url
  app_service_name = local.webhook_service_name
  container_port   = local.webhook_container_port
  env              = local.webhook_env
}

output "cloud_run_webhook_url" {
  value       = module.cloud_run.service_url
  sensitive   = false
  description = "Cloud Run webhook URL."
  depends_on  = [module.cloud_run]
}


# ----------------------------------------------------------------------------------- #
# PubSub push subscription
locals {
  pubsub_topics_push = {
    fastapi_webhook_topic = {
      topic_id       = "fastapi-webhook-topic"
      push_subs_name = "push-fastapi-webhook"
      push_endpoint  = "${module.cloud_run.service_url}/prediction/predict"
    }
  }
}

module "pubsub_push" {
  for_each = local.pubsub_topics_push

  source         = "./modules/gcp/pubsub/push"
  project_id     = data.google_project.current.project_id
  topic_id       = each.value.topic_id
  push_subs_name = each.value.push_subs_name
  push_endpoint  = each.value.push_endpoint

  depends_on = [module.cloud_run]
}

output "pubsub_push_topic" {
  value = {
    for pubsub_topic_key in keys(local.pubsub_topics_push) :
    pubsub_topic_key => module.pubsub_push[pubsub_topic_key].topic
  }
  sensitive   = false
  description = "Pub/Sub push subscription topic"
  depends_on  = [module.pubsub_push]
}

output "pubsub_push_subscriptions" {
  value = {
    for pubsub_topic_key in keys(local.pubsub_topics_push) :
    pubsub_topic_key => module.pubsub_push[pubsub_topic_key].subscription
  }
  sensitive   = false
  description = "Pub/Sub push subscriptions."
  depends_on  = [module.pubsub_push]
}


# ----------------------------------------------------------------------------------- #
# Secret Manager
module "webhook_topic_id_secret" {
  source               = "./modules/gcp/secret"
  project_id           = data.google_project.current.project_id
  secret_source        = 1
  provided_secret_data = module.pubsub_push.fastapi_webhook_topic.topic.id
  secret_type          = "fastapi-webhook-topic"
  environment          = local.environment

  depends_on = [module.pubsub_push]
}

# ----------------------------------------------------------------------------------- #
# Cloud Function
locals {
  cloud_fn_dir_path = var.cloud_fn_dir_path
  cloud_fn_archive  = var.archive_output
  cloud_fn_secrets_id = {
    jwt_secret = "dev-config-jwt-secret"
  }
  cloud_fn_zip_path = var.cloud_fn_zip_path
}


module "cloud_function" {
  source                = "./modules/gcp/cloud-function"
  project_id            = data.google_project.current.project_id
  cloud_fn_zip_path     = local.cloud_fn_zip_path
  location              = local.region
  storage_bucket_name   = local.storage_bucket_name
  service_account_email = local.service_accounts_email.cloud_fn
  secrets_id = {
    jwt_secret       = local.cloud_fn_secrets_id.jwt_secret
    webhook_topic_id = module.webhook_topic_id_secret.secret_name
  }


  depends_on = [module.service_account]
}


