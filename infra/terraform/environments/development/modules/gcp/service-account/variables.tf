variable "environment" {
  type = object({
    prefix = string
    type   = string
  })
  description = "GCP cloud environment."
}

variable "location" {
  type        = string
  description = "Project location."
}

variable "project_name" {
  type        = string
  description = "Project name."
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}
