variable "sa_emails" {
  type = object({
    cloud_fn        = string
    fastapi_webhook = string
  })
  description = "Service accounts email to be assigned specific roles."
}

variable "storage_buckets" {
  type        = list(string)
  description = "List of storage bucket to be accessed by service account."
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}
