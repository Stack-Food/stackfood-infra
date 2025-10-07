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
