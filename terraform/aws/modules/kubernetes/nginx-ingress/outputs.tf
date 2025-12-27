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

output "load_balancer_hostname" {
  description = "The hostname of the Network Load Balancer created by NGINX Ingress Controller"
  value       = try(data.kubernetes_service.nginx_ingress_controller.status[0].load_balancer[0].ingress[0].hostname, "")
}

output "load_balancer_ip" {
  description = "The IP address of the Network Load Balancer created by NGINX Ingress Controller"
  value       = try(data.kubernetes_service.nginx_ingress_controller.status[0].load_balancer[0].ingress[0].ip, "")
}
