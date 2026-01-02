output "loki_url" {
  description = "Internal URL for Loki service"
  value       = "http://loki-stack.${var.namespace}.svc.cluster.local:3100"
}

output "namespace" {
  description = "Namespace where Loki is installed"
  value       = var.namespace
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.loki.name
}

output "chart_version" {
  description = "Version of the Loki Helm chart installed"
  value       = helm_release.loki.version
}
