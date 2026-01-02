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

variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway"
  type        = string
  default     = ""
}

variable "base_path" {
  description = "Base path for the custom domain mapping (empty for root path)"
  type        = string
  default     = "v1"
}

variable "stage_name" {
  description = "The name of the deployment stage"
  type        = string
  default     = "v1"
}

variable "route_key" {
  description = "The route key for the API Gateway route"
  type        = string
  default     = "ANY /{proxy+}"
}

variable "cors_configuration" {
  description = "CORS configuration for the API Gateway"
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_origins     = optional(list(string), ["*"])
    expose_headers    = optional(list(string), ["*"])
    max_age           = optional(number, 86400)
  })
  default = {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}

variable "security_group_name" {
  description = "Name for the VPC Link security group"
  type        = string
  default     = "api-gateway-vpc-link"
}

variable "vpc_link_name" {
  description = "Name for the VPC Link"
  type        = string
  default     = "api-gateway-vpc-link"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "ARN de invoke da Lambda"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda Function name to be integrated with API Gateway"
}

variable "nlb_dns_name" {
  type        = string
  description = "DNS name of the Network Load Balancer from NGINX Ingress Controller"
  default     = ""
}

variable "microservices" {
  type = map(object({
    path = string
    port = number
  }))
  description = "Map of microservices to route through API Gateway via NLB"
  default     = {}
}
