# IMPORTANTE: Ordem de criação dos recursos
# 1. helm_release.grafana cria o namespace automaticamente se não existir (create_namespace = true)
# 2. kubernetes_secret_v1.grafana_oauth é criado no namespace
# 3. Helm instala o chart

# Create Kubernetes Secret for OAuth client secret (after namespace exists)
resource "kubernetes_secret_v1" "grafana_oauth" {
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
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = true # Cria namespace se não existir, não dá erro se já existir
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
      # storage_size e storage_class REMOVIDOS - não usados (persistence desabilitada)
      prometheus_url    = var.prometheus_url
      loki_url          = var.loki_url
      grafana_resources = var.grafana_resources
    }),
    # Configure Prometheus datasource
    var.enable_prometheus_datasource ? yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = concat(
            [
              {
                name      = "Prometheus"
                type      = "prometheus"
                url       = var.prometheus_url
                access    = "proxy"
                isDefault = !var.enable_loki_datasource
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
            ],
            var.enable_loki_datasource ? [
              {
                name      = "Loki"
                type      = "loki"
                url       = var.loki_url
                access    = "proxy"
                isDefault = true
                editable  = true
                jsonData = {
                  maxLines      = 1000
                  derivedFields = []
                }
              }
            ] : []
          )
        }
      }
    }) : ""
  ]

  depends_on = [
    kubernetes_secret_v1.grafana_oauth
  ]
}

