output "argocd_fqdn" {
  description = "Full domain name for ArgoCD"
  value       = var.create_argocd_record ? "${var.argocd_subdomain}.${var.domain_name}" : null
}

output "grafana_fqdn" {
  description = "Full domain name for Grafana"
  value       = var.create_grafana_record ? "${var.grafana_subdomain}.${var.domain_name}" : null
}

output "sonarqube_fqdn" {
  description = "Full domain name for SonarQube"
  value       = var.create_sonarqube_record ? "${var.sonarqube_subdomain}.${var.domain_name}" : null
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
    sonarqube = var.create_sonarqube_record ? {
      name = cloudflare_record.sonarqube[0].name
      fqdn = cloudflare_record.sonarqube[0].name
      type = cloudflare_record.sonarqube[0].type
    } : null
  }
}
