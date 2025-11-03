# Input Variables for QiTlalli Terraform Configuration

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "Google Cloud region for resources"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2",
      "europe-west1", "europe-west2", "europe-west3",
      "asia-east1", "asia-southeast1", "asia-northeast1"
    ], var.region)
    error_message = "Region must be a valid Google Cloud region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "qitlalli"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
  validation {
    condition = contains([
      "db-f1-micro", "db-g1-small", "db-n1-standard-1", 
      "db-n1-standard-2", "db-n1-standard-4"
    ], var.db_tier)
    error_message = "Database tier must be a valid Cloud SQL tier."
  }
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid CIDR notation."
  }
}

variable "filestore_capacity_gb" {
  description = "Filestore capacity in GB"
  type        = number
  default     = 1024
  validation {
    condition     = var.filestore_capacity_gb >= 1024 && var.filestore_capacity_gb <= 65536
    error_message = "Filestore capacity must be between 1024 GB and 65536 GB."
  }
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "gcr.io/PROJECT_ID/qitlalli-odoo:latest"
}

variable "app_cpu" {
  description = "CPU allocation for Cloud Run service"
  type        = string
  default     = "2"
  validation {
    condition = contains([
      "0.25", "0.5", "1", "2", "4", "6", "8"
    ], var.app_cpu)
    error_message = "CPU must be a valid Cloud Run CPU allocation."
  }
}

variable "app_memory" {
  description = "Memory allocation for Cloud Run service"
  type        = string
  default     = "4Gi"
  validation {
    condition = contains([
      "512Mi", "1Gi", "2Gi", "4Gi", "8Gi", "16Gi", "32Gi"
    ], var.app_memory)
    error_message = "Memory must be a valid Cloud Run memory allocation."
  }
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 1
  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 1000
    error_message = "Minimum instances must be between 0 and 1000."
  }
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 1000
    error_message = "Maximum instances must be between 1 and 1000."
  }
}

variable "enable_backup" {
  description = "Enable automated backups for Cloud SQL"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 30
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

variable "enable_ssl" {
  description = "Require SSL connections to Cloud SQL"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for monitoring notifications"
  type        = string
  default     = ""
  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address or empty."
  }
}

# Healthcare-specific variables
variable "hipaa_compliance" {
  description = "Enable HIPAA compliance features (enhanced logging, encryption)"
  type        = bool
  default     = true
}

variable "data_residency_region" {
  description = "Region for data residency compliance (overrides region if set)"
  type        = string
  default     = ""
}

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs for compliance"
  type        = number
  default     = 2555  # 7 years for HIPAA compliance
  validation {
    condition     = var.audit_log_retention_days >= 365
    error_message = "Audit log retention must be at least 365 days for healthcare compliance."
  }
}

# Multi-tenant SaaS variables
variable "enable_multi_tenancy" {
  description = "Enable multi-tenant architecture features"
  type        = bool
  default     = false
}

variable "tenant_isolation_method" {
  description = "Method for tenant isolation (database, schema, row_level)"
  type        = string
  default     = "database"
  validation {
    condition     = contains(["database", "schema", "row_level"], var.tenant_isolation_method)
    error_message = "Tenant isolation method must be database, schema, or row_level."
  }
}

variable "max_tenants" {
  description = "Maximum number of tenants supported"
  type        = number
  default     = 100
  validation {
    condition     = var.max_tenants >= 1 && var.max_tenants <= 10000
    error_message = "Maximum tenants must be between 1 and 10000."
  }
}

# Cost optimization variables
variable "enable_preemptible" {
  description = "Use preemptible instances where possible for cost savings"
  type        = bool
  default     = false
}

variable "auto_scaling_enabled" {
  description = "Enable automatic scaling based on load"
  type        = bool
  default     = true
}

variable "cost_center" {
  description = "Cost center for billing and resource tagging"
  type        = string
  default     = "healthcare-platform"
}

variable "budget_alert_threshold" {
  description = "Monthly budget threshold in USD for cost alerts"
  type        = number
  default     = 500
  validation {
    condition     = var.budget_alert_threshold > 0
    error_message = "Budget alert threshold must be greater than 0."
  }
}