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
    admin_user             = "OptimusFrame"
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

# ============================================
# Messaging Infrastructure Outputs
# ============================================

output "sns_topics" {
  description = "SNS topics created for event-driven architecture"
  value = {
    for topic_name, topic in module.sns : topic_name => {
      topic_arn  = topic.topic_arn
      topic_name = topic.topic_name
      topic_id   = topic.topic_id
    }
  }
}

output "sqs_queues" {
  description = "SQS queues created for event-driven architecture"
  value = {
    for queue_name, queue in module.sqs : queue_name => {
      queue_url  = queue.queue_url
      queue_arn  = queue.queue_arn
      queue_name = queue.queue_name
      dlq_url    = queue.dlq_url
      dlq_arn    = queue.dlq_arn
    }
  }
}

# ============================================
# RabbitMQ Outputs
# ============================================

output "rabbitmq_access_info" {
  description = "RabbitMQ connection and access information"
  value = {
    namespace       = module.rabbitmq.namespace
    service_name    = module.rabbitmq.service_name
    management_url  = module.rabbitmq.management_url
    amqp_port       = 5672
    management_port = 15672
    username        = var.rabbitmq_username
    vhost           = "/"
    connection_info = module.rabbitmq.connection_info
  }
  sensitive = true
}

output "rabbitmq_connection_string" {
  description = "RabbitMQ AMQP connection URL for applications"
  value       = module.rabbitmq.amqp_url
  sensitive   = true
}
