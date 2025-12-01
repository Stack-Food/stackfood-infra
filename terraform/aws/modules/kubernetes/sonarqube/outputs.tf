output "namespace" {
  description = "Kubernetes namespace where SonarQube is deployed"
  value       = var.namespace
}

output "service_name" {
  description = "SonarQube service name"
  value       = "sonarqube"
}

output "service_port" {
  description = "SonarQube service port"
  value       = 9000
}

output "domain_name" {
  description = "Full domain name for SonarQube"
  value       = "${var.sonarqube_subdomain}.${var.domain_name}"
}

output "url" {
  description = "SonarQube URL"
  value       = "https://${var.sonarqube_subdomain}.${var.domain_name}"
}

output "helm_release_name" {
  description = "Helm release name for SonarQube"
  value       = helm_release.sonarqube.name
}

output "helm_release_status" {
  description = "Helm release status for SonarQube"
  value       = helm_release.sonarqube.status
}

output "postgresql_enabled" {
  description = "Whether PostgreSQL is enabled as part of SonarQube deployment"
  value       = var.postgresql_enabled
}

output "initial_credentials" {
  description = "Credenciais iniciais do SonarQube"
  value = {
    username = "admin"
    password = "admin"
    note     = "IMPORTANTE: Altere estas credenciais após o primeiro login em ${var.sonarqube_subdomain}.${var.domain_name}"
  }
}
