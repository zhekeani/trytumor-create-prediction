variable "topic_id" {
  type        = string
  description = "Pub/Sub topic ID"
}

variable "push_endpoint" {
  type        = string
  description = "End point which messages should be pushed"
}

variable "push_subs_name" {
  type        = string
  description = "Push subscription name"
}

variable "project_id" {
  type        = string
  description = "GCP project ID."
}
