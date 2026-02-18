output "namespace" {
  description = "RabbitMQ namespace"
  value       = kubernetes_namespace_v1.rabbitmq.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.rabbitmq.name
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.rabbitmq.status
}

output "service_name" {
  description = "RabbitMQ service name for internal cluster communication"
  value       = "rabbitmq.${kubernetes_namespace_v1.rabbitmq.metadata[0].name}.svc.cluster.local"
}

output "amqp_url" {
  description = "RabbitMQ AMQP connection URL (internal)"
  value       = "amqp://${var.rabbitmq_username}@rabbitmq.${kubernetes_namespace_v1.rabbitmq.metadata[0].name}.svc.cluster.local:${var.amqp_port}"
  sensitive   = true
}

output "management_url" {
  description = "RabbitMQ Management UI URL (internal)"
  value       = "http://rabbitmq.${kubernetes_namespace_v1.rabbitmq.metadata[0].name}.svc.cluster.local:${var.management_port}"
}

output "connection_info" {
  description = "RabbitMQ connection information for applications"
  value = {
    host              = "rabbitmq.${kubernetes_namespace_v1.rabbitmq.metadata[0].name}.svc.cluster.local"
    amqp_port         = var.amqp_port
    management_port   = var.management_port
    username          = var.rabbitmq_username
    vhost             = var.rabbitmq_vhost
    namespace         = kubernetes_namespace_v1.rabbitmq.metadata[0].name
  }
  sensitive = false
}

output "credentials_secret_name" {
  description = "Name of the Kubernetes secret containing RabbitMQ credentials"
  value       = kubernetes_secret_v1.rabbitmq_auth.metadata[0].name
}
