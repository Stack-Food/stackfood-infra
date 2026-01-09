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
