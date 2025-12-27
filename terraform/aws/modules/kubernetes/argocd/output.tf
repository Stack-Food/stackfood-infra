output "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is deployed"
  value       = helm_release.argocd.namespace
}

output "argocd_release_name" {
  description = "Helm release name for ArgoCD"
  value       = helm_release.argocd.name
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = "https://${var.argocd_subdomain}.${var.domain_name}"
}

output "admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl get secret argocd-initial-admin-secret -n ${var.namespace} -o jsonpath=\"{.data.password}\" | base64 --decode"
}