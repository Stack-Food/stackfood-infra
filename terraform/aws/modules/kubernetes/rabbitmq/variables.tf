variable "environment" {
  description = "Environment name (prod, dev, staging)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for RabbitMQ"
  type        = string
  default     = "messaging"
}

variable "chart_version" {
  description = "RabbitMQ Helm chart version"
  type        = string
  default     = "14.0.0" # Latest stable version from Bitnami
}

variable "replicas" {
  description = "Number of RabbitMQ replicas"
  type        = number
  default     = 3
}

# ========================================================================
# Authentication
# ========================================================================
variable "rabbitmq_username" {
  description = "RabbitMQ admin username"
  type        = string
  default     = "admin"
}

variable "rabbitmq_password" {
  description = "RabbitMQ admin password"
  type        = string
  sensitive   = true
}

variable "rabbitmq_erlang_cookie" {
  description = "RabbitMQ Erlang cookie for clustering"
  type        = string
  sensitive   = true
}

variable "rabbitmq_vhost" {
  description = "RabbitMQ virtual host"
  type        = string
  default     = "/"
}

# ========================================================================
# Node Selector (Dedicated Node Group)
# ========================================================================
variable "node_selector_key" {
  description = "Node selector key for dedicated RabbitMQ nodes"
  type        = string
  default     = "workload"
}

variable "node_selector_value" {
  description = "Node selector value for dedicated RabbitMQ nodes"
  type        = string
  default     = "rabbitmq"
}

# ========================================================================
# Storage
# ========================================================================
variable "storage_size" {
  description = "Persistent volume size for RabbitMQ"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for RabbitMQ persistent volumes"
  type        = string
  default     = "gp2"
}

# ========================================================================
# Plugins
# ========================================================================
variable "enable_plugins" {
  description = "RabbitMQ plugins to enable"
  type        = string
  default     = "rabbitmq_management rabbitmq_peer_discovery_k8s rabbitmq_prometheus"
}

variable "enable_management" {
  description = "Enable RabbitMQ management interface"
  type        = bool
  default     = true
}

# ========================================================================
# Ports
# ========================================================================
variable "amqp_port" {
  description = "AMQP port"
  type        = number
  default     = 5672
}

variable "management_port" {
  description = "Management UI port"
  type        = number
  default     = 15672
}

# ========================================================================
# Resources
# ========================================================================
variable "rabbitmq_resources" {
  description = "Resource requests and limits for RabbitMQ pods"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
}

# ========================================================================
# Tags
# ========================================================================
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
