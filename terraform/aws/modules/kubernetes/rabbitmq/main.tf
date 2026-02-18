# ========================================================================
# RabbitMQ Installation via Helm
# ========================================================================
# This module installs RabbitMQ in EKS using the official Bitnami Helm chart
# with a dedicated node group and proper network configuration
# ========================================================================

# Create namespace for RabbitMQ
resource "kubernetes_namespace_v1" "rabbitmq" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Create Kubernetes Secret for RabbitMQ credentials
resource "kubernetes_secret_v1" "rabbitmq_auth" {
  metadata {
    name      = "rabbitmq-auth"
    namespace = kubernetes_namespace_v1.rabbitmq.metadata[0].name
  }

  data = {
    "rabbitmq-password"        = var.rabbitmq_password
    "rabbitmq-erlang-cookie"   = var.rabbitmq_erlang_cookie
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# Install RabbitMQ via Helm
resource "helm_release" "rabbitmq" {
  name             = "rabbitmq"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "rabbitmq"
  namespace        = kubernetes_namespace_v1.rabbitmq.metadata[0].name
  create_namespace = false # Namespace already created above
  version          = var.chart_version

  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  force_update  = false
  recreate_pods = false

  values = [
    templatefile("${path.module}/rabbitmq.yaml", {
      replicas              = var.replicas
      rabbitmq_username     = var.rabbitmq_username
      rabbitmq_vhost        = var.rabbitmq_vhost
      node_selector_key     = var.node_selector_key
      node_selector_value   = var.node_selector_value
      storage_size          = var.storage_size
      storage_class         = var.storage_class
      enable_plugins        = var.enable_plugins
      resources             = var.rabbitmq_resources
      enable_management     = var.enable_management
      management_port       = var.management_port
      amqp_port             = var.amqp_port
    })
  ]

  # Reference existing secret
  set = [
    {
    name  = "auth.existingPasswordSecret"
    value = kubernetes_secret_v1.rabbitmq_auth.metadata[0].name
  },
  {
    name  = "auth.existingErlangSecret"
    value = kubernetes_secret_v1.rabbitmq_auth.metadata[0].name
  }]
  depends_on = [
    kubernetes_namespace_v1.rabbitmq,
    kubernetes_secret_v1.rabbitmq_auth
  ]
}
