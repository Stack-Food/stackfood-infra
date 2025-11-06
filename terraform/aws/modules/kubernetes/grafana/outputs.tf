output "namespace" {
  description = "Grafana namespace"
  value       = var.namespace
}

output "service_name" {
  description = "Grafana service name"
  value       = "grafana"
}

output "url" {
  description = "Grafana URL"
  value       = "https://${var.grafana_subdomain}.${var.domain_name}"
}

output "admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "helm_release_name" {
  description = "Helm release name for Grafana"
  value       = helm_release.grafana.name
}

output "helm_release_namespace" {
  description = "Helm release namespace for Grafana"
  value       = helm_release.grafana.namespace
}

output "datasources_config" {
  description = "Grafana datasources configuration"
  value = {
    prometheus = {
      enabled = var.enable_prometheus_datasource
      url     = var.prometheus_url
    }
  }
}
