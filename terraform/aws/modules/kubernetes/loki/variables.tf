variable "namespace" {
  description = "Namespace where Loki will be installed"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Version of the Loki stack Helm chart"
  type        = string
  default     = "2.10.2"
}

variable "retention_period" {
  description = "Retention period for logs in hours"
  type        = string
  default     = "168h" # 7 days
}

variable "enable_persistence" {
  description = "Enable persistence for Loki"
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Storage size for Loki persistence"
  type        = string
  default     = "10Gi"
}
