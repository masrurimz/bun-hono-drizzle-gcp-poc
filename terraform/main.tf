terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>4.0"
    }

    time = {
      source = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
}

variable "gcp_region" {
  type = string
  description = "GCP Region to deploy to"
  default = "europe-west3"
}

variable "gcp_project" {
  type = string
  description = "Project to deploy to"
}

variable "docker_image" {
  type = string
  description = "Docker image name"
}

provider "google" {
  region = var.gcp_region
  project = var.gcp_project
}

resource "google_artifact_registry_repository" "docker-registry" {
  format        = "DOCKER"
  repository_id = "docker-registry"

#  docker_config {
#    immutable_tags = false
#  }
}

resource "google_artifact_registry_repository_iam_member" "docker_pascal" {
  role          = "roles/artifactregistry.writer"
  location      = google_artifact_registry_repository.docker-registry.location
  repository    = google_artifact_registry_repository.docker-registry.name
  member        = "user:psyma@stud.hs-bremen.de"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_artifact_registry_repository_iam_member.docker_pascal]

  create_duration = "60s"
}


resource "google_cloud_run_service" "app" {
  name     = "hono-app"
  location = var.gcp_region
  depends_on = [time_sleep.wait_60_seconds]

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }

  metadata {
    annotations = {
      "run.googleapis.com/client-name" = "terraform"
    }
  }

  template {
    spec {
      containers {
        image = "${google_artifact_registry_repository.docker-registry.location}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.docker-registry.name}/${var.docker_image}:latest"
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.app.location
  project     = google_cloud_run_service.app.project
  service     = google_cloud_run_service.app.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
output "service_url" {
  value = google_cloud_run_service.app.status[0].url
}