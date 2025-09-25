######################
# Required Variables #
######################

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
}

variable "aws_region" {
  description = "AWS region for Lambda integrations"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster for HTTP integrations"
  type        = string
  default     = null
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for AWS_PROXY integrations"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is located"
  type        = string
  default     = null
}

######################
# Optional Variables #
######################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "endpoint_type" {
  description = "Type of endpoint for the API Gateway (EDGE, REGIONAL, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

# CloudWatch Logs Configuration
variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "log_kms_key_id" {
  description = "KMS key ID for CloudWatch log encryption"
  type        = string
  default     = null
}

variable "enable_access_logs" {
  description = "Enable access logging for API Gateway"
  type        = bool
  default     = true
}

variable "access_log_format" {
  description = "Custom access log format (JSON string)"
  type        = string
  default     = null
}

# API Configuration
variable "policy_document" {
  description = "IAM policy document for the API Gateway"
  type        = string
  default     = null
}

variable "api_key_source" {
  description = "Source of API key (HEADER, AUTHORIZER)"
  type        = string
  default     = null
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API"
  type        = list(string)
  default     = []
}

# CORS Configuration
variable "enable_cors" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "cors_allow_credentials" {
  description = "Whether credentials are included in the CORS request"
  type        = bool
  default     = false
}

variable "cors_allow_headers" {
  description = "List of headers allowed in CORS requests"
  type        = list(string)
  default     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token"]
}

variable "cors_allow_methods" {
  description = "List of HTTP methods allowed in CORS requests"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}

variable "cors_allow_origins" {
  description = "List of origins allowed in CORS requests"
  type        = list(string)
  default     = ["*"]
}

variable "cors_expose_headers" {
  description = "List of headers to expose in CORS response"
  type        = list(string)
  default     = []
}

variable "cors_max_age" {
  description = "Maximum age for CORS preflight requests"
  type        = number
  default     = 86400
}

# Resources Configuration
variable "resources" {
  description = "Map of API Gateway resources to create"
  type = map(object({
    path_part = string
    parent_id = optional(string)
  }))
  default = {}
}

# Methods Configuration
variable "methods" {
  description = "Map of API Gateway methods to create"
  type = map(object({
    resource_key         = optional(string)
    resource_id          = optional(string)
    http_method          = string
    authorization        = string
    authorizer_id        = optional(string)
    authorization_scopes = optional(list(string))
    api_key_required     = optional(bool, false)
    operation_name       = optional(string)
    request_models       = optional(map(string))
    request_validator_id = optional(string)
    request_parameters   = optional(map(bool))
  }))
  default = {}
}

# Integrations Configuration
variable "integrations" {
  description = "Map of API Gateway integrations to create"
  type = map(object({
    method_key              = string
    resource_key            = optional(string)
    resource_id             = optional(string)
    integration_http_method = string
    type                    = string
    uri                     = optional(string)
    # Simplified integration types
    integration_type = optional(string, "custom") # "lambda", "eks", or "custom"
    eks_path         = optional(string, "")       # Path for EKS integrations
    # Original fields
    connection_type      = optional(string)
    connection_id        = optional(string)
    credentials          = optional(string)
    request_templates    = optional(map(string))
    request_parameters   = optional(map(string))
    passthrough_behavior = optional(string)
    cache_key_parameters = optional(list(string))
    cache_namespace      = optional(string)
    content_handling     = optional(string)
    timeout_milliseconds = optional(number)
    tls_config = optional(object({
      insecure_skip_verification = bool
    }))
  }))
  default = {}
}

# Method Responses Configuration
variable "method_responses" {
  description = "Map of API Gateway method responses to create"
  type = map(object({
    method_key          = string
    resource_key        = optional(string)
    resource_id         = optional(string)
    status_code         = string
    response_models     = optional(map(string))
    response_parameters = optional(map(bool))
  }))
  default = {}
}

# Integration Responses Configuration
variable "integration_responses" {
  description = "Map of API Gateway integration responses to create"
  type = map(object({
    method_key          = string
    method_response_key = string
    resource_key        = optional(string)
    resource_id         = optional(string)
    response_templates  = optional(map(string))
    response_parameters = optional(map(string))
    selection_pattern   = optional(string)
    content_handling    = optional(string)
  }))
  default = {}
}

# Deployment Configuration
variable "deployment_description" {
  description = "Description for the API Gateway deployment"
  type        = string
  default     = "Deployed via Terraform"
}

variable "create_stage" {
  description = "Whether to create a stage for the deployment"
  type        = bool
  default     = true
}

variable "stage_description" {
  description = "Description for the API Gateway stage"
  type        = string
  default     = ""
}

variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

# Caching Configuration
variable "cache_cluster_enabled" {
  description = "Enable caching cluster for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster"
  type        = string
  default     = "0.5"
}

# Throttling Configuration
variable "throttle_settings" {
  description = "Throttle settings for the stage"
  type = object({
    rate_limit  = number
    burst_limit = number
  })
  default = null
}

# Monitoring Configuration
variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

# API Keys Configuration
variable "api_keys" {
  description = "Map of API keys to create"
  type = map(object({
    name        = string
    description = optional(string)
    enabled     = optional(bool, true)
  }))
  default = {}
}

# Usage Plans Configuration
variable "usage_plans" {
  description = "Map of usage plans to create"
  type = map(object({
    name         = string
    description  = optional(string)
    product_code = optional(string)
    quota_settings = optional(object({
      limit  = number
      period = string
      offset = optional(number)
    }))
    throttle_settings = optional(object({
      rate_limit  = number
      burst_limit = number
    }))
  }))
  default = {}
}

# Usage Plan Keys Configuration
variable "usage_plan_keys" {
  description = "Map of usage plan keys to create (associates API keys with usage plans)"
  type = map(object({
    api_key    = string
    usage_plan = string
  }))
  default = {}
}

# Lambda Permissions Configuration
variable "lambda_permissions" {
  description = "Map of Lambda permissions to create for API Gateway"
  type = map(object({
    statement_id  = string
    function_name = string
    qualifier     = optional(string)
  }))
  default = {}
}
