######################
# Required Variables #
######################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
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
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled"
  type        = bool
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets. If not provided, a new KMS key will be created."
  type        = string
}

variable "node_groups" {
  description = "Map of EKS Node Group configurations"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

# Variables for IAM roles
variable "cluster_role_name" {
  description = "Name of the IAM role to use for the EKS cluster (e.g., 'LabEksClusterRole')"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role to use for the EKS node groups (e.g., 'LabEksNodeRole')"
  type        = string
}

# Variables for CloudWatch Logs
variable "log_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch Log Group"
  type        = number
}

variable "log_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
}

# Load Balancer Configuration
variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}
variable "enable_remote_management" {
  description = "Whether to enable remote management access to the cluster"
  type        = bool
}

variable "management_cidr_blocks" {
  description = "List of CIDR blocks allowed for remote management access"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for external load balancer"
  type        = list(string)
}

variable "authentication_mode" {
  description = "Authentication mode for EKS cluster (e.g., 'aws', 'oidc')"
  type        = string
}
