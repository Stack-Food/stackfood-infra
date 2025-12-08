variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "domain_name" {
  description = "The primary domain name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

# ArgoCD specific variables
variable "create_argocd_record" {
  description = "Whether to create ArgoCD DNS record"
  type        = bool
  default     = true
}

variable "argocd_subdomain" {
  description = "Subdomain for ArgoCD"
  type        = string
  default     = "argo"
}

# Grafana specific variables
variable "create_grafana_record" {
  description = "Whether to create Grafana DNS record"
  type        = bool
  default     = true
}

variable "grafana_subdomain" {
  description = "Subdomain for Grafana"
  type        = string
  default     = "grafana"
}

variable "proxied" {
  description = "Whether to proxy through Cloudflare"
  type        = bool
  default     = false
}

variable "ttl" {
  description = "TTL for DNS records (ignored if proxied is true)"
  type        = number
  default     = 300
}

# Generic DNS records variable
variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    name     = string
    type     = string
    content  = string
    proxied  = optional(bool)
    ttl      = optional(number)
    priority = optional(number)
    tags     = optional(map(string))
  }))
  default = {}
}
