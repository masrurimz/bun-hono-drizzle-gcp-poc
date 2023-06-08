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

provider "google" {
  region  = var.gcp_region
  project = var.gcp_project
}

provider "google-beta" {
  region  = var.gcp_region
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
  role       = "roles/artifactregistry.writer"
  location   = google_artifact_registry_repository.docker-registry.location
  repository = google_artifact_registry_repository.docker-registry.name
  member     = "user:psyma@stud.hs-bremen.de"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_artifact_registry_repository_iam_member.docker_pascal]

  create_duration = "60s"
}

# VPC access connector
resource "google_vpc_access_connector" "serverless" {
  name           = "vpcconn"
  provider       = google-beta
  ip_cidr_range  = "10.8.0.0/28"
  max_throughput = 300
  network        = google_compute_network.peering_network.name
}

# Cloud Router
resource "google_compute_router" "router" {
  name     = "router"
  provider = google-beta
  network  = google_compute_network.peering_network.id
}

# NAT configuration
resource "google_compute_router_nat" "router_nat" {
  name                               = "nat"
  provider                           = google-beta
  router                             = google_compute_router.router.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}

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
output "service_url" {
  value = google_cloud_run_service.app.status[0].url
}

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

output "sql_ip" {
  value = google_sql_database_instance.instance.private_ip_address
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

output "admin-db" {
  value     = "postgresql://${google_sql_user.database-admin-user.name}:${random_password.db_admin_pwd.result}@/${google_sql_database.database.name}?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
  sensitive = true
}

resource "google_compute_network" "peering_network" {
  name                    = "private-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.peering_network.id
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.peering_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
