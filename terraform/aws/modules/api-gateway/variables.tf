variable "vpc_id" {
  description = "The ID of the VPC where the API Gateway will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the VPC Link"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the VPC Link"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster to integrate with API Gateway"
  type        = string
  default     = null
}

variable "api_name" {
  description = "The name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment for tagging purposes (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for custom domain"
  type        = string
  default     = ""
}
