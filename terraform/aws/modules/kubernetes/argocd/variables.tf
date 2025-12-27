variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "4.0.0"
}

variable "domain_name" {
  description = "Domain name for ArgoCD"
  type        = string
}

variable "argocd_subdomain" {
  description = "Subdomain for ArgoCD"
  type        = string
  default     = "argo"
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

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "admin_group_name" {
  description = "Cognito group name for ArgoCD admin users"
  type        = string
  default     = "argocd-admin"
}

variable "readonly_group_name" {
  description = "Cognito group name for ArgoCD readonly users"
  type        = string
  default     = "argocd-readonly"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "cognito_client_issuer_url" {
  description = "Cognito User Pool Issuer URL"
  type        = string
}

variable "user_pool_name" {
  description = "Base name for the Cognito User Pools"
  type        = string
}
