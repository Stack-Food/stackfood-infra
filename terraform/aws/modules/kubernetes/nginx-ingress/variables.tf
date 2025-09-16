variable "ingress_name" {
  description = "Name of the NGINX Ingress Helm release"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_repository" {
  description = "Helm repository for the NGINX Ingress controller"
  type        = string
  default     = "https://kubernetes.github.io/ingress-nginx"
}

variable "ingress_chart" {
  description = "Helm chart name for the NGINX Ingress controller"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_namespace" {
  description = "Kubernetes namespace to deploy the NGINX Ingress controller"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_version" {
  description = "Version of the NGINX Ingress Helm chart"
  type        = string
  default     = "4.10.0"
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate to use with the load balancer"
  type        = string
  default     = ""
}
