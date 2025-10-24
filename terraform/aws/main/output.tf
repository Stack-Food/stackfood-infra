# Outputs separados para cada User Pool do MESMO módulo
output "application_cognito_info" {
  description = "Informações do User Pool da aplicação"
  value = {
    user_pool_id  = module.cognito.user_pool_id
    user_pool_arn = module.cognito.user_pool_arn
    client_id     = module.cognito.app_client_id
    endpoint      = module.cognito.user_pool_endpoint
  }
}

output "argocd_cognito_info" {
  description = "Informações do User Pool ArgoCD"
  value = {
    user_pool_id  = module.cognito.argocd_user_pool_id
    user_pool_arn = module.cognito.argocd_user_pool_arn
    client_id     = module.cognito.argocd_client_id
    client_secret = module.cognito.argocd_client_secret
    domain        = module.cognito.argocd_domain
    issuer_url    = module.cognito.argocd_issuer_url
  }
  sensitive = true
}

output "argocd_access_info" {
  description = "Informações de acesso ao ArgoCD"
  value = {
    url                    = module.argocd.argocd_url
    admin_user             = "stackfood"
    admin_password         = "Fiap@2025"
    cognito_login_url      = module.cognito.argocd_issuer_url
    admin_password_command = module.argocd.admin_password_command
  }
  sensitive = true
}

output "team_users_info" {
  description = "Informações dos usuários da equipe criados"
  value       = module.cognito.users_summary
  sensitive   = true
}

output "dns_records_created" {
  description = "Registros DNS criados"
  value = {
    argocd_dns = "argo.${var.domain_name}"
    argocd_url = "https://argo.${var.domain_name}"
  }
}

# Output mostrando a estrutura unificada
output "cognito_unified_summary" {
  description = "Resumo do módulo Cognito unificado"
  value = {
    module_structure = "Single module with unified User Pool"
    user_pools       = module.cognito.users_summary
    groups           = module.cognito.groups
    files = {
      main_file    = "main.tf (User Pool and Groups)"
      clients_file = "clients.tf (OAuth clients)"
      outputs_file = "outputs.tf (unified outputs)"
    }
  }
}

# Output para compatibilidade com API Gateway (usando o User Pool da aplicação)
output "api_gateway_config" {
  description = "Configuração para API Gateway Authorizer"
  value       = module.cognito.api_gateway_authorizer_config
}
