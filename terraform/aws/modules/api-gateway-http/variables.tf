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

#####
variable "name" {
  description = "API Gateway name"
  type        = string
}

variable "nlb_listener_arn" {
  description = "ARN do listener do NLB (TCP/HTTP)"
  type        = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "lb_arn" {
  description = "ARN do Load Balancer (NLB) que o API Gateway irá integrar"
  type        = string
}

variable "cluster_security_group_ids" {
  description = "Security Group IDs associados ao cluster EKS"
  type        = string
}

# Lambda Integration Variables
variable "lambda_invoke_arn" {
  description = "ARN de invoke da função Lambda para integração com API Gateway"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Nome da função Lambda para integração com API Gateway"
  type        = string
  default     = ""
}

variable "enable_lambda_integration" {
  description = "Habilitar integração com Lambda para rotas /auth e /customer"
  type        = bool
  default     = false
}

