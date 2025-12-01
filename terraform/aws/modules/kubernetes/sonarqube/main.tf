resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    templatefile("${path.module}/sonarqube.yaml", {
      domain_name             = var.domain_name
      sonarqube_subdomain     = var.sonarqube_subdomain
      certificate_arn         = var.certificate_arn
      storage_size            = var.storage_size
      storage_class           = var.storage_class
      sonarqube_resources     = var.sonarqube_resources
      postgresql_enabled      = var.postgresql_enabled
      postgresql_storage_size = var.postgresql_storage_size
      postgresql_resources    = var.postgresql_resources
      external_database       = var.external_database
      monitoring_passcode     = var.monitoring_passcode
      rds_endpoint            = var.rds_endpoint
      rds_database            = var.rds_database
      rds_username            = var.rds_username
    })
  ]

  # Ensure namespace and secrets exist before installing
  depends_on = [
    kubernetes_namespace.sonarqube,
    kubernetes_secret.sonarqube_postgres
  ]
}

# Create namespace explicitly for better control
resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = var.namespace
    labels = {
      name                           = var.namespace
      "app.kubernetes.io/name"       = "sonarqube"
      "app.kubernetes.io/instance"   = "sonarqube"
      "app.kubernetes.io/part-of"    = "ci-cd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Create secret for PostgreSQL RDS credentials
resource "kubernetes_secret" "sonarqube_postgres" {
  metadata {
    name      = "sonarqube-postgres-secret"
    namespace = var.namespace
  }

  data = {
    password = var.rds_password
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.sonarqube]
}

# Create ServiceMonitor for Prometheus scraping (if monitoring is available)
# Note: This requires the Prometheus Operator to be installed
# resource "kubernetes_manifest" "sonarqube_service_monitor" {
#   manifest = {
#     apiVersion = "monitoring.coreos.com/v1"
#     kind       = "ServiceMonitor"
#     metadata = {
#       name      = "sonarqube"
#       namespace = var.namespace
#       labels = {
#         app                            = "sonarqube"
#         "app.kubernetes.io/name"       = "sonarqube"
#         "app.kubernetes.io/instance"   = "sonarqube"
#         "app.kubernetes.io/part-of"    = "ci-cd"
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "sonarqube"
#         }
#       }
#       endpoints = [
#         {
#           port     = "http"
#           path     = "/api/monitoring/metrics"
#           interval = "30s"
#           params = {
#             format = ["prometheus"]
#           }
#         }
#       ]
#     }
#   }

#   depends_on = [helm_release.sonarqube]
# }
