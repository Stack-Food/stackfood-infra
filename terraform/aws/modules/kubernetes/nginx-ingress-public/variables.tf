variable "namespace" {
  description = "Namespace to deploy NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx-public"
}

variable "chart_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.11.3"
}

variable "depends_on_resources" {
  description = "Resources that this module depends on"
  type        = any
  default     = []
}
