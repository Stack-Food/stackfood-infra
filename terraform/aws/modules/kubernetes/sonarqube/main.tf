resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    templatefile("${path.module}/sonarqube.yaml", {
      domain_name               = var.domain_name
      sonarqube_subdomain       = var.sonarqube_subdomain
      cognito_user_pool_id      = var.cognito_user_pool_id
      cognito_client_id         = var.cognito_client_id
      cognito_client_secret     = var.cognito_client_secret
      cognito_region            = var.cognito_region
      cognito_client_issuer_url = var.cognito_client_issuer_url
      certificate_arn           = var.certificate_arn
      admin_group_name          = var.admin_group_name
      user_group_name           = var.user_group_name
      user_pool_name            = var.user_pool_name
      storage_size              = var.storage_size
      storage_class             = var.storage_class
      sonarqube_resources       = var.sonarqube_resources
      postgresql_enabled        = var.postgresql_enabled
      postgresql_storage_size   = var.postgresql_storage_size
      postgresql_resources      = var.postgresql_resources
      external_database         = var.external_database
      monitoring_passcode       = var.monitoring_passcode
    })
  ]

  # Ensure namespace exists before installing
  depends_on = [
    kubernetes_namespace.sonarqube
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

# Create secret for OIDC configuration
resource "kubernetes_secret" "sonarqube_oidc" {
  metadata {
    name      = "sonarqube-oidc-config"
    namespace = var.namespace
  }

  data = {
    client-id     = var.cognito_client_id
    client-secret = var.cognito_client_secret
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.sonarqube]
}

# Create ConfigMap for SonarQube OIDC configuration
resource "kubernetes_config_map" "sonarqube_config" {
  metadata {
    name      = "sonarqube-oidc-config"
    namespace = var.namespace
  }

  data = {
    "sonar.auth.oidc.enabled"               = "true"
    "sonar.auth.oidc.providerConfiguration" = var.cognito_client_issuer_url
    "sonar.auth.oidc.clientId.secured"      = var.cognito_client_id
    "sonar.auth.oidc.clientSecret.secured"  = var.cognito_client_secret
    "sonar.auth.oidc.issuerUri"             = var.cognito_client_issuer_url
    "sonar.auth.oidc.buttonText"            = "Login with StackFood SSO"
    "sonar.auth.oidc.groupsSync"            = "true"
    "sonar.auth.oidc.groupsSync.claimName"  = "cognito:groups"
    "sonar.auth.oidc.userInfoUrl"           = replace(var.cognito_client_issuer_url, "/.well-known/openid_configuration", "/oauth2/userInfo")
    "sonar.core.serverBaseURL"              = "https://${var.sonarqube_subdomain}.${var.domain_name}"
  }

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
