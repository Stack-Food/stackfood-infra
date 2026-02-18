variable "user_pool_name" {
  description = "Nome base para o Cognito User Pool unificado"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# Unified User Pool Configuration
variable "create_guest_user" {
  description = "Criar usuário convidado para a aplicação"
  type        = bool
  default     = true
}

variable "guest_user_password" {
  description = "Senha para o usuário convidado. Deve ser forte."
  type        = string
  sensitive   = true
}

# System Admin Configuration
variable "OptimusFrame_admin_password" {
  description = "Senha para o usuário administrador OptimusFrame"
  type        = string
  sensitive   = true
  default     = "Fiap@2025"
}

# Team Users Configuration  
variable "team_users" {
  description = "Map de usuários da equipe com seus grupos de acesso"
  type = map(object({
    name      = string
    email     = string
    user_type = optional(string, "team_member")
    groups    = list(string) # Possíveis valores: ["argocd", "grafana", "app-admins", "system-admins"]
  }))
  default = {}
}

variable "team_users_password" {
  description = "Senha padrão para os usuários da equipe"
  type        = string
  sensitive   = true
  default     = "OptimusFrame@2025"
}

# Client Configuration
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

variable "grafana_callback_urls" {
  description = "List of callback URLs for Grafana OIDC (for future use)"
  type        = list(string)
  default     = []
}

variable "grafana_logout_urls" {
  description = "List of logout URLs for Grafana OIDC (for future use)"
  type        = list(string)
  default     = []
}
