variable "location" {
  type        = string
  description = "Location where the Cloud Run will be deployed."
}


variable "secrets_id" {
  type = object({
    jwt_secret       = string
    webhook_topic_id = string
  })
  description = "Secrets ID for secrets that will be retrieved from Secret Manager."
}


variable "service_account_email" {
  type        = string
  description = "Service account used by cloud function."
}

variable "storage_bucket_name" {
  type        = string
  description = "Storage bucket name."
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "cloud_fn_zip_path" {
  type        = string
  description = "Storage bucket path to uploaded cloud function zipped source code."
}

output "function_uri" {
  value = google_cloudfunctions2_function.function.service_config[0].uri
}