output "argocd_fqdn" {
  description = "Full domain name for ArgoCD"
  value       = var.create_argocd_record ? "${var.argocd_subdomain}.${var.domain_name}" : null
}

output "grafana_fqdn" {
  description = "Full domain name for Grafana"
  value       = var.create_grafana_record ? "${var.grafana_subdomain}.${var.domain_name}" : null
}

output "cloudflare_records" {
  description = "Map of all created Cloudflare records"
  value = {
    argocd = var.create_argocd_record ? {
      name = cloudflare_record.argocd[0].name
      fqdn = cloudflare_record.argocd[0].name
      type = cloudflare_record.argocd[0].type
    } : null
    grafana = var.create_grafana_record ? {
      name = cloudflare_record.grafana[0].name
      fqdn = cloudflare_record.grafana[0].name
      type = cloudflare_record.grafana[0].type
    } : null
  }
}

output "argocd_dns_name" {
  description = "DNS name for ArgoCD"
  value       = var.create_argocd_record ? "${var.argocd_subdomain}.${var.domain_name}" : null
}

output "argocd_record_id" {
  description = "Cloudflare record ID for ArgoCD"
  value       = var.create_argocd_record ? cloudflare_record.argocd[0].id : null
}

output "argocd_url" {
  description = "Full URL for ArgoCD access"
  value       = var.create_argocd_record ? "https://${var.argocd_subdomain}.${var.domain_name}" : null
}

output "grafana_dns_name" {
  description = "DNS name for Grafana"
  value       = var.create_grafana_record ? "${var.grafana_subdomain}.${var.domain_name}" : null
}

output "grafana_record_id" {
  description = "Cloudflare record ID for Grafana"
  value       = var.create_grafana_record ? cloudflare_record.grafana[0].id : null
}

output "grafana_url" {
  description = "Full URL for Grafana access"
  value       = var.create_grafana_record ? "https://${var.grafana_subdomain}.${var.domain_name}" : null
}
