output "prometheus_url" {
  description = "Internal URL for Prometheus service"
  value       = "http://prometheus-server.${var.namespace}.svc.cluster.local"
}

output "namespace" {
  description = "Namespace where Prometheus is installed"
  value       = var.namespace
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.prometheus.name
}

output "chart_version" {
  description = "Version of the Prometheus Helm chart installed"
  value       = helm_release.prometheus.version
}
