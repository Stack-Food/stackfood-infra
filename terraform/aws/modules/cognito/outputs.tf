
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
  value = {
    user_pool_id  = aws_cognito_user_pool.argocd.id
    user_pool_arn = aws_cognito_user_pool.argocd.arn
    client_id     = aws_cognito_user_pool_client.argocd.id
    client_secret = aws_cognito_user_pool_client.argocd.client_secret
    issuer_url    = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.argocd.id}"
    domain        = aws_cognito_user_pool_domain.argocd.domain
    admin_group   = aws_cognito_user_group.argocd_admin.name
    endpoint      = aws_cognito_user_pool.argocd.endpoint
  }
  sensitive = true
}

# ArgoCD User Pool specific outputs
output "argocd_user_pool_id" {
  description = "ID do Cognito User Pool dedicado para ArgoCD"
  value       = aws_cognito_user_pool.argocd.id
}

output "argocd_user_pool_arn" {
  description = "ARN do Cognito User Pool dedicado para ArgoCD"
  value       = aws_cognito_user_pool.argocd.arn
}

output "argocd_client_id" {
  description = "ID do client ArgoCD"
  value       = aws_cognito_user_pool_client.argocd.id
}

output "argocd_client_secret" {
  description = "Secret do client ArgoCD"
  value       = aws_cognito_user_pool_client.argocd.client_secret
  sensitive   = true
}

output "argocd_domain" {
  description = "Domínio do User Pool ArgoCD"
  value       = aws_cognito_user_pool_domain.argocd.domain
}

output "argocd_issuer_url" {
  description = "URL do issuer OIDC para ArgoCD"
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.argocd.id}"
}

output "argocd_team_users_created" {
  description = "Lista dos usuários da equipe criados no ArgoCD"
  value = length(var.argocd_team_users) > 0 ? {
    users = [
      for username, user in var.argocd_team_users : {
        username = username
        name     = user.name
        email    = user.email
      }
    ]
    password   = var.argocd_team_password
    access_url = "https://argo.stackfood.com.br"
    group      = "argocd-admin"
    note       = "Emails de convite foram enviados para todos os usuários"
  } : null
  sensitive = true
}

output "user_pools_summary" {
  description = "Resumo dos User Pools criados"
  value = {
    app_user_pool = var.create_app_user_pool ? {
      name    = "${var.user_pool_name}-app"
      id      = aws_cognito_user_pool.app[0].id
      purpose = "Autenticação da aplicação principal"
      users   = ["convidado (guest)"]
    } : null
    argocd_user_pool = {
      name        = "${var.user_pool_name}-argocd"
      id          = aws_cognito_user_pool.argocd.id
      purpose     = "Autenticação exclusiva do ArgoCD"
      admin_users = concat(["stackfood (admin)"], keys(var.argocd_team_users))
      total_users = 1 + length(var.argocd_team_users)
    }
  }
}

output "stackfood_user_created" {
  description = "Confirmation that stackfood user was created"
  value       = "User 'stackfood' created with admin privileges in ArgoCD User Pool"
}
