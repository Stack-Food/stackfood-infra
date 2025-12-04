variable "namespace" {
  description = "Kubernetes namespace for SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "chart_version" {
  description = "SonarQube Helm chart version"
  type        = string
  default     = "10.7.0+3598"
}

variable "domain_name" {
  description = "Domain name for SonarQube"
  type        = string
}

variable "sonarqube_subdomain" {
  description = "Subdomain for SonarQube"
  type        = string
  default     = "sonar"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

# Storage Configuration
variable "storage_size" {
  description = "Storage size for SonarQube data persistence"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for SonarQube persistence"
  type        = string
  default     = "gp2"
}

# Resource Configuration
variable "sonarqube_resources" {
  description = "Resource requests and limits for SonarQube"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "400m"
      memory = "2048M"
    }
    limits = {
      cpu    = "800m"
      memory = "6144M"
    }
  }
}

# PostgreSQL Configuration
variable "postgresql_enabled" {
  description = "Enable embedded PostgreSQL database"
  type        = bool
  default     = true
}

variable "postgresql_storage_size" {
  description = "Storage size for PostgreSQL data"
  type        = string
  default     = "20Gi"
}

variable "postgresql_resources" {
  description = "Resource configuration for PostgreSQL"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "200Mi"
    }
    limits = {
      cpu    = "2"
      memory = "2Gi"
    }
  }
}

# External database configuration (optional)
variable "external_database" {
  description = "External database configuration"
  type = object({
    enabled  = bool
    host     = string
    port     = number
    name     = string
    username = string
    password = string
  })
  default = {
    enabled  = false
    host     = ""
    port     = 5432
    name     = ""
    username = ""
    password = ""
  }
}

# RDS Configuration for external PostgreSQL
variable "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  type        = string
  default     = ""
}

variable "rds_database" {
  description = "RDS database name for SonarQube"
  type        = string
  default     = "sonarqube"
}

variable "rds_username" {
  description = "RDS database username"
  type        = string
  default     = "sonarqube"
}

variable "rds_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
  default     = ""
}

# Monitoring Configuration
variable "monitoring_passcode" {
  description = "Monitoring passcode for SonarQube health checks"
  type        = string
  sensitive   = true
  default     = "sonarqube-monitoring-pass"
}

# GitHub App Integration Configuration
variable "github_app_enabled" {
  description = "Enable GitHub App integration with SonarQube"
  type        = bool
  default     = true
}

variable "github_app_id" {
  description = "GitHub App ID for SonarQube integration"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_id" {
  description = "GitHub App Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub App Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_private_key" {
  description = "GitHub App Private Key (PEM format)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_webhook_secret" {
  description = "GitHub Webhook Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_organization" {
  description = "GitHub Organization name"
  type        = string
  default     = ""
}

variable "github_api_url" {
  description = "GitHub API URL (use https://api.github.com for github.com)"
  type        = string
  default     = "https://api.github.com"
}

variable "github_integration_key" {
  description = "Unique key for GitHub integration in SonarQube"
  type        = string
  default     = "github"
}

variable "sonarqube_admin_user" {
  description = "SonarQube admin username for API configuration"
  type        = string
  default     = "admin"
}

variable "sonarqube_admin_password" {
  description = "SonarQube admin password for API configuration"
  type        = string
  default     = "admin"
  sensitive   = true
}

