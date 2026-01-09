######################
# DNS Cloudflare Module #
######################

# DNS Record para ArgoCD
resource "cloudflare_record" "argocd" {
  count = var.create_argocd_record ? 1 : 0

  zone_id         = var.cloudflare_zone_id
  name            = var.argocd_subdomain
  type            = "CNAME"
  content         = var.public_nlb_dns_name
  proxied         = var.proxied
  ttl             = var.proxied ? 1 : var.ttl
  allow_overwrite = true

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Record para Grafana
resource "cloudflare_record" "grafana" {
  count = var.create_grafana_record ? 1 : 0

  zone_id         = var.cloudflare_zone_id
  name            = var.grafana_subdomain
  type            = "CNAME"
  content         = var.public_nlb_dns_name
  proxied         = var.proxied
  ttl             = var.proxied ? 1 : var.ttl
  allow_overwrite = true

  lifecycle {
    create_before_destroy = true
  }
}
