variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Artifact Registry + regional services region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "GKE regional location (Autopilot uses regions)"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "web-autopilot"
}

variable "artifact_repo" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "my-docker-repo"
}
