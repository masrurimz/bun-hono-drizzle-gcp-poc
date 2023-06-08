terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~>4.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
}

provider "google" {
  region  = var.gcp_region
  project = var.gcp_project
}

provider "google-beta" {
  region  = var.gcp_region
  project = var.gcp_project
}

#
# DOCKER
#

resource "google_artifact_registry_repository" "docker-registry" {
  format        = "DOCKER"
  repository_id = "docker-registry"

  #  docker_config {
  #    immutable_tags = false
  #  }
}

resource "google_artifact_registry_repository_iam_member" "docker_pascal" {
  role       = "roles/artifactregistry.writer"
  location   = google_artifact_registry_repository.docker-registry.location
  repository = google_artifact_registry_repository.docker-registry.name
  member     = "user:psyma@stud.hs-bremen.de"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_artifact_registry_repository_iam_member.docker_pascal]

  create_duration = "60s"
}

#
# RUN
#

resource "google_cloud_run_service" "app" {
  name                       = "hono-app"
  location                   = var.gcp_region
  depends_on                 = [time_sleep.wait_60_seconds]
  autogenerate_revision_name = true

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
        env {
          name  = "PG_HOST"
          value = "${google_sql_database_instance.instance.private_ip_address}:5432"
        }
        env {
          name  = "PG_USER"
          value = "run"
        }
        env {
          name  = "PG_PASSWORD"
          value = random_password.db_pwd.result
        }
        env {
          name  = "PG_DB"
          value = google_sql_database.database.name
        }
      }
    }
    metadata {
      labels = {
        "run.googleapis.com/startupProbeType" = "Default"
      }
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.serverless.name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.app.location
  project  = google_cloud_run_service.app.project
  service  = google_cloud_run_service.app.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

#
# SQL
#

resource "google_sql_database_instance" "instance" {
  name                = "hono-db"
  region              = var.gcp_region
  database_version    = "POSTGRES_13"
  deletion_protection = true

  depends_on = [google_service_networking_connection.default]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = true
      private_network                               = google_compute_network.peering_network.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = "hono"
  instance = google_sql_database_instance.instance.name
}

resource "random_password" "db_pwd" {
  length  = 16
  special = false
}

resource "google_sql_user" "database-user" {
  name     = "run"
  instance = google_sql_database_instance.instance.name
  password = random_password.db_pwd.result
}

resource "random_password" "db_admin_pwd" {
  length  = 32
  special = false
}

resource "google_sql_user" "database-admin-user" {
  name     = "admin"
  instance = google_sql_database_instance.instance.name
  password = random_password.db_pwd.result
}
