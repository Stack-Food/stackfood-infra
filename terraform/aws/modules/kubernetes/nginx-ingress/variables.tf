variable "ingress_name" {
  description = "Name of the NGINX Ingress Helm release"
  type        = string
}

variable "ingress_repository" {
  description = "Helm repository for the NGINX Ingress controller"
  type        = string
}

variable "ingress_chart" {
  description = "Helm chart name for the NGINX Ingress controller"
  type        = string
}

variable "ingress_namespace" {
  description = "Kubernetes namespace to deploy the NGINX Ingress controller"
  type        = string
}

variable "ingress_version" {
  description = "Version of the NGINX Ingress Helm chart"
  type        = string
}

