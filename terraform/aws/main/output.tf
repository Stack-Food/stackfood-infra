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
    argocd_dns  = "argo.${var.domain_name}"
    argocd_url  = "https://argo.${var.domain_name}"
    grafana_dns = "grafana.${var.domain_name}"
    grafana_url = "https://grafana.${var.domain_name}"
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

# Outputs do Grafana
output "grafana_cognito_info" {
  description = "Informações do Cognito para Grafana"
  value = {
    user_pool_id  = module.cognito.user_pool_id
    client_id     = module.cognito.grafana_client_id
    client_secret = module.cognito.grafana_client_secret
    issuer_url    = module.cognito.grafana_issuer_url
  }
  sensitive = true
}

output "grafana_access_info" {
  description = "Informações de acesso ao Grafana"
  value = {
    url               = module.grafana.url
    namespace         = module.grafana.namespace
    admin_user        = module.grafana.admin_user
    admin_password    = "admin" # Senha padrão inicial
    cognito_login_url = module.cognito.grafana_issuer_url
  }
  sensitive = true
}

output "monitoring_setup" {
  description = "Configuração de monitoramento implementada"
  value = {
    grafana = {
      url            = module.grafana.url
      namespace      = module.grafana.namespace
      datasources    = module.grafana.datasources_config
      dashboards     = ["Kubernetes Cluster", "Node Exporter Full"]
      authentication = "Cognito OAuth2"
    }
    prometheus_integration = {
      enabled        = true
      url            = "http://prometheus-server.monitoring.svc.cluster.local"
      node_exporter  = "Enabled via EKS add-on"
      metrics_server = "Enabled via EKS add-on"
    }
    access_control = {
      admin_groups    = ["system-admins", "grafana"]
      readonly_groups = ["grafana-readonly"]
      shared_cognito  = "Same User Pool as ArgoCD"
    }
  }
}

output "sonarqube_access_info" {
  description = "Informações de acesso ao SonarQube"
  value = {
    url              = module.sonarqube.url
    namespace        = module.sonarqube.namespace
    initial_username = "admin"
    initial_password = "admin"
    important_note   = "ATENÇÃO: Altere as credenciais padrão após o primeiro login!"
    authentication   = "Built-in authentication (default) - SAML pode ser configurado via UI"
    saml_guide       = "Consulte terraform/aws/modules/kubernetes/sonarqube/README-SAML.md para configurar SAML"
    github_guide     = "Consulte terraform/aws/modules/kubernetes/sonarqube/README-GitHub-Integration.md para detalhes"
  }
  sensitive = true
}
