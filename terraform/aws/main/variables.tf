######################
# General Variables #
######################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

######################
# VPC Configuration #
######################

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "CIDR block for the VPC"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_subnets" {
  description = "Map of private subnets to create in the VPC"
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  default = {
    "private1" = {
      availability_zone = "us-west-2a"
      cidr_block        = "10.0.1.0/24"
    },
    "private2" = {
      availability_zone = "us-west-2b"
      cidr_block        = "10.0.2.0/24"
    },
    "private3" = {
      availability_zone = "us-west-2c"
      cidr_block        = "10.0.3.0/24"
    }
  }
}

variable "public_subnets" {
  description = "Map of public subnets to create in the VPC"
  type = map(object({
    availability_zone = string
    cidr_block        = string
  }))
  default = {
    "public1" = {
      availability_zone = "us-west-2a"
      cidr_block        = "10.0.101.0/24"
    },
    "public2" = {
      availability_zone = "us-west-2b"
      cidr_block        = "10.0.102.0/24"
    },
    "public3" = {
      availability_zone = "us-west-2c"
      cidr_block        = "10.0.103.0/24"
    }
  }
}

######################
# EKS Configuration #
######################

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_node_groups" {
  description = "Map of EKS Node Group configurations"
  type = map(object({
    desired_size              = number
    max_size                  = number
    min_size                  = number
    ami_type                  = string
    capacity_type             = string
    instance_types            = list(string)
    disk_size                 = number
    ssh_key                   = optional(string, null)
    source_security_group_ids = optional(list(string), [])
    labels                    = optional(map(string), {})
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
    "app" = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]
      disk_size      = 20
      labels = {
        "role" = "app"
      }
    },
    "db" = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]
      disk_size      = 20
      labels = {
        "role" = "db"
      }
    }
  }
}

######################
# RDS Configuration #
######################

variable "rds_instances" {
  description = "Identifier for the RDS instance"
}

######################
# Lambda Configuration #
######################

variable "lambda_functions" {
  description = "List of Lambda functions to create"
  type = list(object({
    name                  = string
    description           = string
    runtime               = string
    handler               = string
    filename              = string
    source_code_hash      = string
    memory_size           = number
    timeout               = number
    vpc_access            = bool
    environment_variables = map(string)
  }))
  default = []
}

######################
# IAM Configuration #
######################

variable "lambda_role_name" {
  description = "Name of the IAM role to use for Lambda functions"
  type        = string
  default     = "LabRole"
}

variable "eks_cluster_role_name" {
  description = "Name of the IAM role to use for the EKS cluster"
  type        = string
  default     = "LabEksClusterRole"
}

variable "eks_node_role_name" {
  description = "Name of the IAM role to use for the EKS node groups"
  type        = string
  default     = "LabEksNodeRole"
}
