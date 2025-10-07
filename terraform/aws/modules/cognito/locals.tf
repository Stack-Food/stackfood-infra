# Cognito Module
# Este módulo cria dois User Pools independentes:
# 1. User Pool para a aplicação (app-user-pool.tf)
# 2. User Pool para ArgoCD (argocd-user-pool.tf)

# Locals para configurações compartilhadas
locals {
  common_tags = {
    Environment = var.environment
    Module      = "cognito"
    ManagedBy   = "terraform"
  }
  
  app_pool_name    = "${var.user_pool_name}-app"
  argocd_pool_name = "${var.user_pool_name}-argocd"
}