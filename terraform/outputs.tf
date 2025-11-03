# Output Values for QiTlalli Terraform Configuration
# These outputs can be used by other systems or for reference

output "project_info" {
  description = "Project configuration information"
  value = {
    project_id  = var.project_id
    region      = var.region
    environment = var.environment
  }
}

output "database_info" {
  description = "Database connection information"
  value = {
    instance_name       = google_sql_database_instance.qitlalli_db.name
    connection_name     = google_sql_database_instance.qitlalli_db.connection_name
    database_name       = google_sql_database.qitlalli_database.name
    private_ip_address  = google_sql_database_instance.qitlalli_db.private_ip_address
  }
  sensitive = false
}

output "database_credentials" {
  description = "Database user credentials (password stored in Secret Manager)"
  value = {
    username         = google_sql_user.qitlalli_user.name
    password_secret  = google_secret_manager_secret.qitlalli_secrets["qitlalli-db-password"].secret_id
  }
  sensitive = true
}

output "service_account_info" {
  description = "Service account information"
  value = {
    email      = google_service_account.qitlalli_app.email
    unique_id  = google_service_account.qitlalli_app.unique_id
  }
}

output "network_info" {
  description = "Network configuration"
  value = {
    vpc_name       = google_compute_network.qitlalli_vpc.name
    vpc_id         = google_compute_network.qitlalli_vpc.id
    subnet_name    = google_compute_subnetwork.qitlalli_subnet.name
    subnet_cidr    = google_compute_subnetwork.qitlalli_subnet.ip_cidr_range
  }
}

output "storage_info" {
  description = "Storage configuration"
  value = {
    filestore_name = google_filestore_instance.qitlalli_filestore.name
    filestore_ip   = google_filestore_instance.qitlalli_filestore.networks[0].ip_addresses[0]
    file_share     = google_filestore_instance.qitlalli_filestore.file_shares[0].name
  }
}

output "secret_manager_info" {
  description = "Secret Manager configuration"
  value = {
    secrets = {
      for secret_name, secret in google_secret_manager_secret.qitlalli_secrets :
      secret_name => {
        secret_id = secret.secret_id
        name      = secret.name
      }
    }
  }
  sensitive = false
}

output "cloud_run_info" {
  description = "Cloud Run service information"
  value = {
    service_name = google_cloud_run_v2_service.qitlalli_app.name
    service_url  = google_cloud_run_v2_service.qitlalli_app.uri
    location     = google_cloud_run_v2_service.qitlalli_app.location
  }
}

# Healthcare-specific outputs
output "compliance_info" {
  description = "Healthcare compliance configuration"
  value = {
    hipaa_compliance        = var.hipaa_compliance
    audit_log_retention     = var.audit_log_retention_days
    ssl_enabled            = var.enable_ssl
    backup_enabled         = var.enable_backup
    backup_retention       = var.backup_retention_days
  }
}

# Multi-tenancy outputs
output "multi_tenancy_info" {
  description = "Multi-tenancy configuration"
  value = {
    enabled            = var.enable_multi_tenancy
    isolation_method   = var.tenant_isolation_method
    max_tenants       = var.max_tenants
  }
}

# Cost management outputs
output "cost_management" {
  description = "Cost management configuration"
  value = {
    cost_center           = var.cost_center
    budget_threshold      = var.budget_alert_threshold
    preemptible_enabled   = var.enable_preemptible
    auto_scaling_enabled  = var.auto_scaling_enabled
  }
}

# API endpoints for application integration
output "api_endpoints" {
  description = "API endpoints for application configuration"
  value = {
    cloud_run_url         = google_cloud_run_v2_service.qitlalli_app.uri
    health_check_url      = "${google_cloud_run_v2_service.qitlalli_app.uri}/web/health"
    admin_url            = "${google_cloud_run_v2_service.qitlalli_app.uri}/web"
  }
}

# Monitoring and logging endpoints
output "monitoring_info" {
  description = "Monitoring and logging configuration"
  value = {
    enabled               = var.enable_monitoring
    notification_email    = var.notification_email != "" ? var.notification_email : "not_configured"
    cloud_sql_logs       = "https://console.cloud.google.com/logs/viewer?project=${var.project_id}&resource=cloudsql_database"
    cloud_run_logs       = "https://console.cloud.google.com/logs/viewer?project=${var.project_id}&resource=cloud_run_revision"
  }
}

# Security information
output "security_info" {
  description = "Security configuration summary"
  value = {
    service_account_email = google_service_account.qitlalli_app.email
    vpc_enabled          = true
    private_sql          = true
    ssl_required         = var.enable_ssl
    secret_manager       = true
    iam_roles_count      = length(google_project_iam_member.qitlalli_app_roles)
  }
}

# Deployment information for CI/CD
output "deployment_info" {
  description = "Information needed for application deployment"
  value = {
    container_registry   = "gcr.io/${var.project_id}"
    cloud_build_project  = var.project_id
    cloud_run_service    = google_cloud_run_v2_service.qitlalli_app.name
    cloud_run_region     = google_cloud_run_v2_service.qitlalli_app.location
  }
}

# Resource identifiers for external tools
output "resource_ids" {
  description = "Resource identifiers for external tool integration"
  value = {
    sql_instance_id      = google_sql_database_instance.qitlalli_db.id
    cloud_run_service_id = google_cloud_run_v2_service.qitlalli_app.id
    vpc_id               = google_compute_network.qitlalli_vpc.id
    filestore_id         = google_filestore_instance.qitlalli_filestore.id
  }
}