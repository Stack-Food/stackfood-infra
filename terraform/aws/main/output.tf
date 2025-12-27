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

output "messaging_summary" {
  description = "Complete summary of messaging infrastructure for microservices"
  value = {
    customers = {
      publishes_to = [
        {
          topic_name = "stackfood-customer-events"
          topic_arn  = module.sns["stackfood-customer-events"].topic_arn
        }
      ]
      consumes_from = []
    }
    orders = {
      publishes_to = [
        {
          topic_name = "stackfood-order-events"
          topic_arn  = module.sns["stackfood-order-events"].topic_arn
        }
      ]
      consumes_from = [
        {
          queue_name = "stackfood-order-payment-events-queue"
          queue_url  = module.sqs["stackfood-order-payment-events-queue"].queue_url
          source     = "payment-events"
        },
        {
          queue_name = "stackfood-order-production-events-queue"
          queue_url  = module.sqs["stackfood-order-production-events-queue"].queue_url
          source     = "production-events"
        }
      ]
    }
    payments = {
      publishes_to = [
        {
          topic_name = "stackfood-payment-events"
          topic_arn  = module.sns["stackfood-payment-events"].topic_arn
        }
      ]
      consumes_from = [
        {
          queue_name = "stackfood-payment-events-queue"
          queue_url  = module.sqs["stackfood-payment-events-queue"].queue_url
          source     = "order-events"
        }
      ]
    }
    production = {
      publishes_to = [
        {
          topic_name = "stackfood-production-events"
          topic_arn  = module.sns["stackfood-production-events"].topic_arn
        }
      ]
      consumes_from = [
        {
          queue_name = "stackfood-production-events-queue"
          queue_url  = module.sqs["stackfood-production-events-queue"].queue_url
          source     = "order-events"
        }
      ]
    }
  }
}

output "configmap_values" {
  description = "Values to update in Kubernetes ConfigMaps for each microservice"
  value = {
    customers = {
      "AWS__SNS__CustomerEventsTopicArn" = module.sns["stackfood-customer-events"].topic_arn
    }
    orders = {
      "AWS__SNS__OrderCreatedTopicArn"     = module.sns["stackfood-order-events"].topic_arn
      "AWS__SQS__PaymentEventsQueueUrl"    = module.sqs["stackfood-order-payment-events-queue"].queue_url
      "AWS__SQS__ProductionEventsQueueUrl" = module.sqs["stackfood-order-production-events-queue"].queue_url
    }
    payments = {
      "AWS__SNS__PaymentEventsTopicArn" = module.sns["stackfood-payment-events"].topic_arn
      "AWS__SQS__OrderEventsQueueUrl"   = module.sqs["stackfood-payment-events-queue"].queue_url
    }
    production = {
      "AWS__SNS__TopicArn" = module.sns["stackfood-production-events"].topic_arn
      "AWS__SQS__QueueUrl" = module.sqs["stackfood-production-events-queue"].queue_url
    }
  }
}
