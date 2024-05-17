variable "location" {
  type        = string
  description = "Location where the Cloud Run will be deployed."
}

variable "docker_image_url" {
  type        = string
  description = "Docker image URL used by Cloud Run."
}

variable "app_service_name" {
  type        = string
  description = "Cloud Run app service name."
}

variable "container_port" {
  type        = number
  description = "Container port to forward."
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}


variable "env" {
  type = object({
    project_id          = string
    service_account_key = string
    bucket_name         = string
    jwt_secret          = string
  })
  sensitive   = true
  description = "description"
}


output "service_url" {
  value       = google_cloud_run_service.run_service.status[0].url
  description = "Cloud Run server URL."
}