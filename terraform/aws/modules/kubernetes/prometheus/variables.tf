variable "namespace" {
  description = "Namespace where Prometheus will be installed"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Version of the Prometheus Helm chart"
  type        = string
  default     = "25.27.0"
}

variable "retention_days" {
  description = "Retention period for Prometheus metrics in days"
  type        = number
  default     = 15
}

variable "enable_persistence" {
  description = "Enable persistence for Prometheus"
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Storage size for Prometheus persistence"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for Prometheus PVC"
  type        = string
  default     = "gp2"
}
