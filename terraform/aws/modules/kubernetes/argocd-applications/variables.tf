# ArgoCD Applications Module Variables

variable "namespace" {
  description = "Namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "project_name" {
  description = "ArgoCD project name"
  type        = string
  default     = "stackfood"
}

variable "source_repo_url" {
  description = "Source repository URL for applications"
  type        = string
  default     = "https://github.com/Stack-Food/stackfood-api.git"
}

variable "target_revision" {
  description = "Target revision (branch/tag) to sync"
  type        = string
  default     = "master"
}

variable "destination_server" {
  description = "Destination Kubernetes server"
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "api_namespace" {
  description = "Namespace for API deployment"
  type        = string
  default     = "stackfood"
}

variable "worker_namespace" {
  description = "Namespace for Worker deployment"
  type        = string
  default     = "stackfood"
}

variable "enable_auto_sync" {
  description = "Enable automatic sync for applications"
  type        = bool
  default     = false
}

variable "enable_self_heal" {
  description = "Enable self-healing for applications"
  type        = bool
  default     = true
}

variable "enable_prune" {
  description = "Enable pruning of resources"
  type        = bool
  default     = true
}

variable "enable_develop_environment" {
  description = "Enable development environment application"
  type        = bool
  default     = false
}

variable "allowed_source_repos" {
  description = "List of allowed source repositories"
  type        = list(string)
  default = [
    "https://github.com/Stack-Food/*",
    "https://github.com/Stack-Food/stackfood-api.git",
    "https://github.com/Stack-Food/stackfood-infra.git"
  ]
}
