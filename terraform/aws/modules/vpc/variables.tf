######################
# Required Variables #
######################

variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
}

variable "igw_name" {
  description = "The name of the Internet Gateway."
  type        = string
}

variable "ngw_name" {
  description = "The name of the NAT Gateway."
  type        = string
}

variable "route_table_name" {
  description = "The name of the Route Table."
  type        = string
}

variable "environment" {
  description = "The environment this infrastructure is for (e.g., dev, prod)."
  type        = string
}

######################
# Optional Variables #
######################

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_blocks" {
  description = "A list of IPv4 CIDR blocks for the VPC."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "vpc_enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "subnets_private" {
  description = "A map of private subnets to create in the VPC."
  default = {
    "subnet" = {
      availability_zone = null
      cidr_block        = "10.0.0.0/24"
    }
  }
}

variable "subnets_public" {
  description = "A map of public subnets to create in the VPC."
  default = {
    "subnet" = {
      availability_zone = null
      cidr_block        = "10.0.1.0/24"
    }
  }
}

variable "cluster_name" {
  description = "The name of the EKS cluster to integrate with the VPC."
  type        = string
  default     = null
}
