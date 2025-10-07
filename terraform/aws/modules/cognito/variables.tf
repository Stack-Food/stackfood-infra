variable "user_pool_name" {
  description = "Nome do Cognito User Pool"
  type        = string
}

variable "environment" {
  description = "dev"
  type        = string
}

variable "guest_user_password" {
  description = "Senha para o usuário convidado. Deve ser forte."
  type        = string
  sensitive   = true
}

variable "argocd_user_pool_name" {
  description = "Nome do User Pool para ArgoCD"
  type        = string
  default     = "argocd-user-pool"
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
