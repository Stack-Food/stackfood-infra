variable "user_pool_name" {
  description = "Nome base para os Cognito User Pools"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# Application User Pool Configuration
variable "create_app_user_pool" {
  description = "Criar User Pool para a aplicação"
  type        = bool
  default     = true
}

variable "guest_user_password" {
  description = "Senha para o usuário convidado. Deve ser forte."
  type        = string
  sensitive   = true
}

# ArgoCD User Pool Configuration
variable "create_argocd_user_pool" {
  description = "Criar User Pool para ArgoCD"
  type        = bool
  default     = true
}

variable "stackfood_admin_password" {
  description = "Senha para o usuário administrador stackfood"
  type        = string
  sensitive   = true
  default     = "Fiap@2025"
}

variable "argocd_callback_urls" {
  description = "List of callback URLs for ArgoCD OIDC"
  type        = list(string)
  default     = []
}

variable "argocd_logout_urls" {
  description = "List of logout URLs for ArgoCD OIDC"
  type        = list(string)
  default     = []
}
