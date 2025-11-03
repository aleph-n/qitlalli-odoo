# QiTlalli Healthcare Platform - Terraform Configuration
# Infrastructure as Code for Google Cloud Platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # Remote state backend (recommended for team collaboration)
  backend "gcs" {
    bucket = "qitlalli-terraform-state"
    prefix = "terraform/state"
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Local values for resource naming and tagging
locals {
  environment = var.environment
  project_name = "qitlalli"
  
  # Consistent resource naming
  resource_prefix = "${local.project_name}-${local.environment}"
  
  # Common labels for all resources
  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
    purpose     = "healthcare-platform"
  }
}

# Enable required Google Cloud APIs
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "file.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = var.project_id
  service = each.key
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Service Account for QiTlalli application
resource "google_service_account" "qitlalli_app" {
  account_id   = "${local.resource_prefix}-service-account"
  display_name = "QiTlalli Application Service Account"
  description  = "Service account for QiTlalli healthcare platform"
  
  depends_on = [google_project_service.enabled_apis]
}

# IAM roles for service account
resource "google_project_iam_member" "qitlalli_app_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/logging.logWriter", 
    "roles/monitoring.metricWriter",
    "roles/run.invoker"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.qitlalli_app.email}"
}

# Cloud SQL instance for PostgreSQL database
resource "google_sql_database_instance" "qitlalli_db" {
  name             = "${local.resource_prefix}-db"
  database_version = "POSTGRES_15"
  region          = var.region
  
  settings {
    tier = var.db_tier
    
    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.qitlalli_vpc.id
      require_ssl     = true
    }
    
    database_flags {
      name  = "log_statement"
      value = "all"
    }
    
    maintenance_window {
      day         = 7  # Sunday
      hour        = 4  # 4 AM
      update_track = "stable"
    }
    
    user_labels = local.common_labels
  }
  
  depends_on = [
    google_project_service.enabled_apis,
    google_compute_network.qitlalli_vpc
  ]
}

# Database for QiTlalli
resource "google_sql_database" "qitlalli_database" {
  name     = var.database_name
  instance = google_sql_database_instance.qitlalli_db.name
  charset  = "UTF8"
  collation = "en_US.UTF8"
}

# Database user (password will be managed via Secret Manager)
resource "google_sql_user" "qitlalli_user" {
  name     = "qitlalli_user"
  instance = google_sql_database_instance.qitlalli_db.name
  password = random_password.db_password.result
}

# Generate secure database password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# VPC Network for private communication
resource "google_compute_network" "qitlalli_vpc" {
  name                    = "${local.resource_prefix}-vpc"
  auto_create_subnetworks = false
  description            = "VPC network for QiTlalli healthcare platform"
}

# Subnet for application resources
resource "google_compute_subnetwork" "qitlalli_subnet" {
  name          = "${local.resource_prefix}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.qitlalli_vpc.id
  
  description = "Subnet for QiTlalli application resources"
}

# Filestore instance for persistent file storage
resource "google_filestore_instance" "qitlalli_filestore" {
  name = "${local.resource_prefix}-filestore"
  location = "${var.region}-a"
  tier = "BASIC_HDD"
  
  file_shares {
    capacity_gb = var.filestore_capacity_gb
    name        = "odoo_data"
  }
  
  networks {
    network = google_compute_network.qitlalli_vpc.name
    modes   = ["MODE_IPV4"]
  }
  
  labels = local.common_labels
  
  depends_on = [google_project_service.enabled_apis]
}

# Secret Manager secrets for sensitive configuration
resource "google_secret_manager_secret" "qitlalli_secrets" {
  for_each = toset([
    "qitlalli-db-password",
    "qitlalli-admin-password", 
    "qitlalli-jwt-secret",
    "qitlalli-email-password",
    "qitlalli-whatsapp-token"
  ])
  
  secret_id = each.key
  
  replication {
    auto {}
  }
  
  labels = local.common_labels
  
  depends_on = [google_project_service.enabled_apis]
}

# Database password secret version
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.qitlalli_secrets["qitlalli-db-password"].id
  secret_data = random_password.db_password.result
}

# Admin password secret version  
resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.qitlalli_secrets["qitlalli-admin-password"].id
  secret_data = random_password.admin_password.result
}

# Generate admin password
resource "random_password" "admin_password" {
  length  = 24
  special = true
}

# JWT secret
resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.qitlalli_secrets["qitlalli-jwt-secret"].id
  secret_data = random_password.jwt_secret.result
}

# Generate JWT secret
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

# Grant service account access to secrets
resource "google_secret_manager_secret_iam_member" "qitlalli_app_secret_access" {
  for_each = google_secret_manager_secret.qitlalli_secrets
  
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.qitlalli_app.email}"
}

# Cloud Run service (application deployment)
resource "google_cloud_run_v2_service" "qitlalli_app" {
  name     = "${local.resource_prefix}-app"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"
  
  template {
    service_account = google_service_account.qitlalli_app.email
    
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    containers {
      image = var.app_image
      
      resources {
        limits = {
          cpu    = var.app_cpu
          memory = var.app_memory
        }
      }
      
      env {
        name  = "DB_HOST"
        value = "localhost"
      }
      
      env {
        name  = "DB_PORT" 
        value = "5432"
      }
      
      env {
        name  = "DB_NAME"
        value = google_sql_database.qitlalli_database.name
      }
      
      env {
        name  = "DB_USER"
        value = google_sql_user.qitlalli_user.name
      }
      
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.qitlalli_secrets["qitlalli-db-password"].secret_id
            version = "latest"
          }
        }
      }
      
      env {
        name = "ODOO_ADMIN_PASSWD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.qitlalli_secrets["qitlalli-admin-password"].secret_id
            version = "latest"
          }
        }
      }
      
      env {
        name  = "GOOGLE_CLOUD_SQL_CONNECTION_NAME"
        value = google_sql_database_instance.qitlalli_db.connection_name
      }
      
      env {
        name  = "PRODUCTION"
        value = "true"
      }
      
      env {
        name  = "DEBUG"
        value = "false"
      }
    }
    
    annotations = {
      "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.qitlalli_db.connection_name
      "run.googleapis.com/cpu-throttling"     = "false"
    }
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.enabled_apis,
    google_sql_database_instance.qitlalli_db,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.admin_password
  ]
}

# Allow unauthenticated access to Cloud Run service
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.qitlalli_app.location
  service  = google_cloud_run_v2_service.qitlalli_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}