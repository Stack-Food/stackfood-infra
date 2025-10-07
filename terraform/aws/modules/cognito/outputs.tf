
###########################
# Application User Pool Outputs #
###########################

output "app_user_pool_id" {
  description = "ID do Cognito User Pool da aplicação"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].id : null
}

output "app_user_pool_arn" {
  description = "ARN do Cognito User Pool da aplicação"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].arn : null
}

output "app_user_pool_client_id" {
  description = "ID do client da aplicação"
  value       = var.create_app_user_pool ? aws_cognito_user_pool_client.app[0].id : null
}

output "app_user_pool_endpoint" {
  description = "Endpoint do Cognito User Pool da aplicação"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].endpoint : null
}

# Configuração pronta para API Gateway Authorizer
output "api_gateway_authorizer_config" {
  description = "Configuração para authorizer do API Gateway"
  value = var.create_app_user_pool ? {
    type          = "COGNITO_USER_POOLS"
    user_pool_arn = aws_cognito_user_pool.app[0].arn
    user_pool_id  = aws_cognito_user_pool.app[0].id
    client_id     = aws_cognito_user_pool_client.app[0].id
  } : null
}

# Backwards compatibility outputs (deprecated)
output "user_pool_id" {
  description = "ID do Cognito User Pool da aplicação (deprecated - use app_user_pool_id)"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].id : null
}

output "user_pool_arn" {
  description = "ARN do Cognito User Pool da aplicação (deprecated - use app_user_pool_arn)"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].arn : null
}

output "user_pool_client_id" {
  description = "ID do client da aplicação (deprecated - use app_user_pool_client_id)"
  value       = var.create_app_user_pool ? aws_cognito_user_pool_client.app[0].id : null
}

output "user_pool_endpoint" {
  description = "Endpoint do Cognito User Pool da aplicação (deprecated - use app_user_pool_endpoint)"
  value       = var.create_app_user_pool ? aws_cognito_user_pool.app[0].endpoint : null
}

# ArgoCD OIDC Configuration (Dedicated User Pool)
output "argocd_oidc_config" {
  description = "Configuração OIDC para ArgoCD (User Pool dedicado)"
  value = var.create_argocd_user_pool ? {
    user_pool_id   = aws_cognito_user_pool.argocd[0].id
    user_pool_arn  = aws_cognito_user_pool.argocd[0].arn
    client_id      = aws_cognito_user_pool_client.argocd[0].id
    client_secret  = aws_cognito_user_pool_client.argocd[0].client_secret
    issuer_url     = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.argocd[0].id}"
    domain         = aws_cognito_user_pool_domain.argocd[0].domain
    admin_group    = aws_cognito_user_group.argocd_admin[0].name
    readonly_group = aws_cognito_user_group.argocd_readonly[0].name
    endpoint       = aws_cognito_user_pool.argocd[0].endpoint
  } : null
  sensitive = true
}

# ArgoCD User Pool specific outputs
output "argocd_user_pool_id" {
  description = "ID do Cognito User Pool dedicado para ArgoCD"
  value       = var.create_argocd_user_pool ? aws_cognito_user_pool.argocd[0].id : null
}

output "argocd_user_pool_arn" {
  description = "ARN do Cognito User Pool dedicado para ArgoCD"
  value       = var.create_argocd_user_pool ? aws_cognito_user_pool.argocd[0].arn : null
}

output "argocd_client_id" {
  description = "ID do client ArgoCD"
  value       = var.create_argocd_user_pool ? aws_cognito_user_pool_client.argocd[0].id : null
}

output "argocd_client_secret" {
  description = "Secret do client ArgoCD"
  value       = var.create_argocd_user_pool ? aws_cognito_user_pool_client.argocd[0].client_secret : null
  sensitive   = true
}

output "argocd_domain" {
  description = "Domínio do User Pool ArgoCD"
  value       = var.create_argocd_user_pool ? aws_cognito_user_pool_domain.argocd[0].domain : null
}

output "argocd_issuer_url" {
  description = "URL do issuer OIDC para ArgoCD"
  value       = var.create_argocd_user_pool ? "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.argocd[0].id}" : null
}

output "stackfood_user_created" {
  description = "Confirmation that stackfood user was created"
  value       = var.create_argocd_user_pool ? "User 'stackfood' created with admin privileges in ArgoCD User Pool" : "ArgoCD User Pool not created"
}

# Summary output
output "user_pools_summary" {
  description = "Resumo dos User Pools criados neste módulo"
  value = {
    app_user_pool = var.create_app_user_pool ? {
      id      = aws_cognito_user_pool.app[0].id
      name    = aws_cognito_user_pool.app[0].name
      purpose = "API Gateway e aplicação principal"
      users   = ["convidado (guest)"]
    } : null

    argocd_user_pool = var.create_argocd_user_pool ? {
      id      = aws_cognito_user_pool.argocd[0].id
      name    = aws_cognito_user_pool.argocd[0].name
      purpose = "Autenticação ArgoCD OIDC"
      users   = ["stackfood (admin)"]
    } : null
  }
}
