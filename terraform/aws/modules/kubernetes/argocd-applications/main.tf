# Terraform Provider Requirements
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

# StackFood ArgoCD Project
resource "kubectl_manifest" "stackfood_project" {
  yaml_body = templatefile("${path.module}/configs/projects/stackfood-project.yaml", {
    project_name       = var.project_name
    namespace          = var.namespace
    source_repo_url    = var.source_repo_url
    api_namespace      = var.api_namespace
    worker_namespace   = var.worker_namespace
    destination_server = var.destination_server
  })
}

# StackFood Namespaces Application
resource "kubectl_manifest" "stackfood_namespaces" {
  yaml_body = templatefile("${path.module}/configs/applications/stackfood-namespaces.yaml", {
    namespace          = var.namespace
    project_name       = var.project_name
    source_repo_url    = var.source_repo_url
    target_revision    = var.target_revision
    destination_server = var.destination_server
  })

  depends_on = [kubectl_manifest.stackfood_project]
}

# StackFood API Master Application
resource "kubectl_manifest" "stackfood_api_master" {
  yaml_body = templatefile("${path.module}/configs/applications/stackfood-api.yaml", {
    namespace          = var.namespace
    project_name       = var.project_name
    source_repo_url    = var.source_repo_url
    target_revision    = var.target_revision
    api_namespace      = var.api_namespace
    destination_server = var.destination_server
  })

  depends_on = [kubectl_manifest.stackfood_namespaces]
}

# StackFood Worker Master Application
resource "kubectl_manifest" "stackfood_worker_master" {
  yaml_body = templatefile("${path.module}/configs/applications/stackfood-worker.yaml", {
    namespace          = var.namespace
    project_name       = var.project_name
    source_repo_url    = var.source_repo_url
    target_revision    = var.target_revision
    worker_namespace   = var.worker_namespace
    destination_server = var.destination_server
  })

  depends_on = [kubectl_manifest.stackfood_namespaces]
}
