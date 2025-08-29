######################
# Required Variables #
######################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "List of subnet IDs for the EKS worker nodes. Usually private subnets."
  type        = list(string)
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

######################
# Optional Variables #
######################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets. If not provided, a new KMS key will be created."
  type        = string
  default     = null
}

variable "node_groups" {
  description = "Map of EKS Node Group configurations"
  type = map(object({
    desired_size  = number
    max_size      = number
    min_size      = number
    ami_type      = string
    capacity_type = string
    instance_types = list(string)
    disk_size     = number
    ssh_key       = optional(string, null)
    source_security_group_ids = optional(list(string), [])
    labels        = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    launch_template = optional(object({
      id      = string
      version = string
    }), null)
  }))
  default = {
    "default" = {
      desired_size  = 2
      max_size      = 4
      min_size      = 1
      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"
      instance_types = ["t3.medium"]
      disk_size     = 20
    }
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

# Variables for IAM roles
variable "cluster_role_name" {
  description = "Name of the IAM role to use for the EKS cluster (e.g., 'LabEksClusterRole')"
  type        = string
  default     = "LabEksClusterRole"
}

variable "node_role_name" {
  description = "Name of the IAM role to use for the EKS node groups (e.g., 'LabEksNodeRole')"
  type        = string
  default     = "LabEksNodeRole"
}

# Variables for CloudWatch Logs
variable "log_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch Log Group"
  type        = number
  default     = 30
}

variable "log_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}
