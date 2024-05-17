# Enable the used APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.project_id
  enable_apis                 = true
  disable_services_on_destroy = false

  activate_apis = [
    "pubsub.googleapis.com",
  ]
}

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 6.0"

  topic      = var.topic_id
  project_id = var.project_id
}

resource "google_pubsub_subscription" "push_subscription" {
  ack_deadline_seconds       = 300
  message_retention_duration = "604800s"
  name                       = var.push_subs_name
  project                    = var.project_id
  topic                      = module.pubsub.topic

  expiration_policy {
    ttl = "1209600s"
  }

  push_config {
    push_endpoint = var.push_endpoint
    no_wrapper {
      write_metadata = true
    }
    attributes = {
      x-goog-version = "v1beta1"
    }

  }

  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }

  depends_on = [module.pubsub]
}


output "topic" {
  value = {
    id   = module.pubsub.id
    name = module.pubsub.topic
    uri  = module.pubsub.uri
  }
  sensitive   = false
  description = "Pub/Sub topic ID"
  depends_on  = [module.pubsub]
}

output "subscription" {
  value       = google_pubsub_subscription.push_subscription.id
  sensitive   = false
  description = "Pub/Sub push subscription"
  depends_on  = [google_pubsub_subscription.push_subscription]
}


