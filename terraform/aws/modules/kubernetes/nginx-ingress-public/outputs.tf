output "namespace" {
  description = "Namespace onde o NGINX Ingress Controller público foi instalado"
  value       = var.namespace
}

output "ingress_class_name" {
  description = "Nome da IngressClass criada"
  value       = "nginx-public"
}

output "release_name" {
  description = "Nome do Helm release"
  value       = helm_release.nginx_ingress_public.name
}

output "service_name" {
  description = "Nome do service do NGINX Ingress Controller"
  value       = "${helm_release.nginx_ingress_public.name}-controller"
}

output "load_balancer_dns" {
  description = "DNS name do NLB criado pelo NGINX Ingress Controller (disponível após criação)"
  value       = try(data.kubernetes_service_v1.nginx_ingress_public.status[0].load_balancer[0].ingress[0].hostname, "")
}
