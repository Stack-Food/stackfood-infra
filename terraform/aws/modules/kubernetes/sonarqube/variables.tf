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

# Cognito OIDC Configuration
variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for OIDC"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito App Client ID"
  type        = string
}

variable "cognito_client_secret" {
  description = "Cognito App Client Secret"
  type        = string
  sensitive   = true
}

variable "cognito_region" {
  description = "AWS region where Cognito is deployed"
  type        = string
}

variable "cognito_client_issuer_url" {
  description = "Cognito OIDC issuer URL"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "admin_group_name" {
  description = "Cognito group name for SonarQube administrators"
  type        = string
  default     = "admins"
}

variable "user_group_name" {
  description = "Cognito group name for SonarQube users"
  type        = string
  default     = "users"
}

variable "user_pool_name" {
  description = "Cognito User Pool name"
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

# Monitoring Configuration
variable "monitoring_passcode" {
  description = "Monitoring passcode for SonarQube health checks"
  type        = string
  sensitive   = true
  default     = "sonarqube-monitoring-pass"
}
