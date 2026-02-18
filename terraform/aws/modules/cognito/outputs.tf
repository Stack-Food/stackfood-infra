
###########################
# Main User Pool Outputs  #
###########################

output "user_pool_id" {
  description = "ID do Cognito User Pool unificado"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN do Cognito User Pool unificado"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_name" {
  description = "Nome do Cognito User Pool unificado"
  value       = aws_cognito_user_pool.main.name
}

output "user_pool_endpoint" {
  description = "Endpoint do Cognito User Pool unificado"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domínio do User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

###########################
# Application Client Outputs #
###########################

output "app_client_id" {
  description = "ID do client da aplicação principal"
  value       = aws_cognito_user_pool_client.app.id
}

# Configuração para API Gateway Authorizer
output "api_gateway_authorizer_config" {
  description = "Configuração para authorizer do API Gateway"
  value = {
    type          = "COGNITO_USER_POOLS"
    user_pool_arn = aws_cognito_user_pool.main.arn
    user_pool_id  = aws_cognito_user_pool.main.id
    client_id     = aws_cognito_user_pool_client.app.id
  }
}

###########################
# ArgoCD Client Outputs   #
###########################

output "argocd_client_id" {
  description = "ID do client ArgoCD"
  value       = aws_cognito_user_pool_client.argocd.id
}

output "argocd_client_secret" {
  description = "Secret do client ArgoCD"
  value       = aws_cognito_user_pool_client.argocd.client_secret
  sensitive   = true
}

output "argocd_issuer_url" {
  description = "URL do issuer OIDC para ArgoCD"
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

# ArgoCD OIDC Configuration
output "argocd_oidc_config" {
  description = "Configuração OIDC completa para ArgoCD"
  value = {
    user_pool_id  = aws_cognito_user_pool.main.id
    user_pool_arn = aws_cognito_user_pool.main.arn
    client_id     = aws_cognito_user_pool_client.argocd.id
    client_secret = aws_cognito_user_pool_client.argocd.client_secret
    issuer_url    = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
    domain        = aws_cognito_user_pool_domain.main.domain
    endpoint      = aws_cognito_user_pool.main.endpoint
  }
  sensitive = true
}

###########################
# Grafana Client Outputs  #
###########################

output "grafana_client_id" {
  description = "ID do client Grafana"
  value       = aws_cognito_user_pool_client.grafana.id
}

output "grafana_client_secret" {
  description = "Secret do client Grafana"
  value       = aws_cognito_user_pool_client.grafana.client_secret
  sensitive   = true
}

output "grafana_issuer_url" {
  description = "URL do issuer OIDC para Grafana"
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

###########################
# Groups Outputs          #
###########################

output "groups" {
  description = "Informações sobre os grupos criados"
  value = {
    app_users = {
      name = aws_cognito_user_group.app_users.name
      id   = aws_cognito_user_group.app_users.id
    }
    app_admins = {
      name = aws_cognito_user_group.app_admins.name
      id   = aws_cognito_user_group.app_admins.id
    }
    argocd = {
      name = aws_cognito_user_group.argocd.name
      id   = aws_cognito_user_group.argocd.id
    }
    grafana = {
      name = aws_cognito_user_group.grafana.name
      id   = aws_cognito_user_group.grafana.id
    }
    system_admins = {
      name = aws_cognito_user_group.system_admins.name
      id   = aws_cognito_user_group.system_admins.id
    }
  }
}

###########################
# Users Summary           #
###########################

output "users_summary" {
  description = "Resumo dos usuários criados"
  value = {
    user_pool = {
      name    = aws_cognito_user_pool.main.name
      id      = aws_cognito_user_pool.main.id
      purpose = "Autenticação unificada para aplicação e ferramentas de gerenciamento"
    }
    users_created = {
      guest_user = var.create_guest_user ? {
        username = "convidado"
        email    = "convidado@optimus-frame.com.br"
        groups   = ["app-users"]
      } : null
      admin_user = {
        username = "OptimusFrame"
        email    = "admin@optimus-frame.com.br"
        groups   = ["system-admins", "argocd", "grafana"]
      }
      team_users = {
        for username, user in var.team_users : username => {
          name   = user.name
          email  = user.email
          groups = user.groups
        }
      }
    }
    total_users = 1 + (var.create_guest_user ? 1 : 0) + length(var.team_users)
  }
}

###########################
# Backward Compatibility  #
###########################

# Mantendo outputs para compatibilidade com configuração atual
output "argocd_user_pool_id" {
  description = "ID do User Pool (compatibilidade)"
  value       = aws_cognito_user_pool.main.id
}

output "argocd_user_pool_name" {
  description = "Nome do User Pool (compatibilidade)"
  value       = aws_cognito_user_pool.main.name
}

output "argocd_user_pool_arn" {
  description = "ARN do User Pool (compatibilidade)"
  value       = aws_cognito_user_pool.main.arn
}

output "argocd_domain" {
  description = "Domínio do User Pool (compatibilidade)"
  value       = aws_cognito_user_pool_domain.main.domain
}
