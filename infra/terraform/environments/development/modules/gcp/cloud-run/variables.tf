variable "location" {
  type        = string
  description = "Location where the Cloud Run will be deployed."
}

variable "docker_image_url" {
  type        = string
  description = "Docker image URL used by Cloud Run."
}

variable "jwt_config" {
  type        = string
  sensitive   = true
  description = "JWT configuration used inside FastAPI web server."
}

variable app_service_name {
  type        = string
  description = "Cloud Run app service name."
}
