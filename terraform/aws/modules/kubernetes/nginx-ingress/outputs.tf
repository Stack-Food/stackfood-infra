output "ingress_ready" {
  description = "Indicates that NGINX Ingress Controller and its admission webhook are ready"
  value       = null_resource.wait_for_ingress_webhook.id
}

output "namespace" {
  description = "Namespace where NGINX Ingress Controller is deployed"
  value       = var.ingress_namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.ingress-nginx.name
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.ingress-nginx.status
}
