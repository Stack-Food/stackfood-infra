# ArgoCD Applications Module Outputs

output "project_name" {
  description = "Name of the ArgoCD project"
  value       = var.project_name
}

output "applications" {
  description = "Map of created ArgoCD applications"
  value = {
    namespaces = {
      name      = "stackfood-namespaces"
      namespace = var.namespace
    }
    api_master = {
      name      = "stackfood-api-master"
      namespace = var.namespace
    }
    api_develop = var.enable_develop_environment ? {
      name      = "stackfood-api-develop"
      namespace = var.namespace
    } : null
  }
}

output "source_repository" {
  description = "Source repository URL"
  value       = var.source_repo_url
}

output "target_revision" {
  description = "Target revision being deployed"
  value       = var.target_revision
}

output "sync_policy" {
  description = "Sync policy configuration"
  value = {
    auto_sync = var.enable_auto_sync
    self_heal = var.enable_self_heal
    prune     = var.enable_prune
  }
}

output "configuration_summary" {
  description = "Summary of module configuration"
  value = {
    project          = var.project_name
    repository       = var.source_repo_url
    branch           = var.target_revision
    api_namespace    = var.api_namespace
    worker_namespace = var.worker_namespace
    auto_sync        = var.enable_auto_sync
    develop_env      = var.enable_develop_environment
  }
}
