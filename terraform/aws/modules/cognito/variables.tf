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
