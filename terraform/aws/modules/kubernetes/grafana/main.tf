# IMPORTANTE: Ordem de criação dos recursos
# 1. kubernetes_namespace cria o namespace PRIMEIRO
# 2. kubernetes_secret.grafana_oauth é criado no namespace
# 3. helm_release.grafana instala o chart (create_namespace = false, pois já existe)

# Create namespace first
resource "kubernetes_namespace" "grafana" {
  metadata {
    name = var.namespace
    labels = {
      name                           = var.namespace
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "monitoring"
    }
  }
}

# Create Kubernetes Secret for OAuth client secret (after namespace exists)
resource "kubernetes_secret" "grafana_oauth" {
  metadata {
    name      = "grafana-oauth-secret"
    namespace = var.namespace
  }

  data = {
    "GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET" = var.cognito_client_secret
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }

  depends_on = [
    kubernetes_namespace.grafana
  ]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = false # Namespace já foi criado acima
  version          = var.chart_version

  # Adicionar timeouts para ações de CI/CD
  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  # Forçar update se necessário
  force_update  = false
  recreate_pods = false

  values = [
    templatefile("${path.module}/grafana.yaml", {
      domain_name               = var.domain_name
      grafana_subdomain         = var.grafana_subdomain
      cognito_user_pool_id      = var.cognito_user_pool_id
      cognito_client_id         = var.cognito_client_id
      cognito_client_secret     = var.cognito_client_secret
      cognito_region            = var.cognito_region
      cognito_client_issuer_url = var.cognito_client_issuer_url
      certificate_arn           = var.certificate_arn
      admin_group_name          = var.admin_group_name
      readonly_group_name       = var.readonly_group_name
      system_admin_group_name   = var.system_admin_group_name
      user_pool_name            = var.user_pool_name
      storage_size              = var.storage_size
      storage_class             = var.storage_class
      prometheus_url            = var.prometheus_url
      grafana_resources         = var.grafana_resources
    }),
    var.enable_prometheus_datasource ? yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = var.prometheus_url
              access    = "proxy"
              isDefault = true
              editable  = true
              jsonData = {
                timeInterval = "5s"
                queryTimeout = "300s"
                httpMethod   = "POST"
              }
            },
            {
              name      = "Node Exporter"
              type      = "prometheus"
              url       = var.prometheus_url
              access    = "proxy"
              isDefault = false
              editable  = true
              jsonData = {
                timeInterval                = "5s"
                queryTimeout                = "300s"
                httpMethod                  = "POST"
                exemplarTraceIdDestinations = []
              }
            }
          ]
        }
      }
    }) : ""
  ]

  depends_on = [
    kubernetes_namespace.grafana,
    kubernetes_secret.grafana_oauth
  ]
}

# Data source para o namespace (já criado)
data "kubernetes_namespace" "grafana" {
  metadata {
    name = var.namespace
  }

  depends_on = [
    kubernetes_namespace.grafana
  ]
}

# Create additional ConfigMap with Kubernetes dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards-kubernetes"
    namespace = var.namespace
    labels = {
      grafana_dashboard = "1"
      app               = "grafana"
    }
  }

  data = {
    "kubernetes-cluster-monitoring.json" = file("${path.module}/dashboards/kubernetes-cluster.json")
    "node-exporter-full.json"            = file("${path.module}/dashboards/node-exporter.json")
  }

  depends_on = [
    helm_release.grafana
  ]
}
