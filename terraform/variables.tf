variable "gcp_region" {
  type        = string
  description = "GCP Region to deploy to"
  default     = "europe-west3"
}

variable "gcp_project" {
  type        = string
  description = "Project to deploy to"
}

variable "docker_image" {
  type        = string
  description = "Docker image name"
}