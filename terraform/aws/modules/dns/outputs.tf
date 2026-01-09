# Outputs básicos para referência
output "argocd_url" {
  description = "Full URL for ArgoCD access"
  value       = var.create_argocd_record ? "https://${var.argocd_subdomain}.${var.domain_name}" : null
}

output "grafana_url" {
  description = "Full URL for Grafana access"
  value       = var.create_grafana_record ? "https://${var.grafana_subdomain}.${var.domain_name}" : null
}
