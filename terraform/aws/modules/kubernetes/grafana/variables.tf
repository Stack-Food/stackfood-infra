variable "namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Grafana Helm chart version"
  type        = string
  default     = "8.5.2"
}

variable "domain_name" {
  description = "Domain name for Grafana"
  type        = string
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana"
  type        = string
  default     = "grafana"
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
  description = "Cognito User Pool Issuer URL"
  type        = string
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "admin_group_name" {
  description = "Cognito group name for Grafana admin users"
  type        = string
  default     = "grafana-admin"
}

variable "readonly_group_name" {
  description = "Cognito group name for Grafana readonly users"
  type        = string
  default     = "grafana-readonly"
}

variable "system_admin_group_name" {
  description = "Cognito group name for system admin users"
  type        = string
  default     = "system-admins"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "user_pool_name" {
  description = "Base name for the Cognito User Pools"
  type        = string
}

# Storage Configuration
# ⚠️ NOTA: Estas variáveis são mantidas para compatibilidade com prod.tfvars
# mas NÃO são usadas porque persistence está desabilitada no grafana.yaml
# Quando o EBS CSI Driver for habilitado, essas variáveis voltarão a ser usadas
variable "storage_size" {
  description = "Size of the persistent volume for Grafana (OBSOLETO - persistence desabilitada)"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for Grafana persistent volume (OBSOLETO - persistence desabilitada)"
  type        = string
  default     = "gp2"
}

# Resource Configuration
variable "grafana_resources" {
  description = "Resource requests and limits for Grafana"
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
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Prometheus Configuration
variable "prometheus_url" {
  description = "Prometheus URL for metrics scraping"
  type        = string
  default     = "http://prometheus-server.monitoring.svc.cluster.local"
}

variable "enable_prometheus_datasource" {
  description = "Enable Prometheus as default datasource"
  type        = bool
  default     = true
}

variable "enable_service_monitor" {
  description = "Enable ServiceMonitor for Prometheus Operator (requires prometheus-operator CRDs installed)"
  type        = bool
  default     = false
}
