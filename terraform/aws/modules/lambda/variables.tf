######################
# Required Variables #
######################

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
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

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

# Package Type
variable "package_type" {
  description = "Lambda deployment package type (Zip or Image)"
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be either 'Zip' or 'Image'."
  }
}

# For ZIP packages
variable "handler" {
  description = "Handler function entrypoint (required for Zip packages)"
  type        = string
  default     = null
}

variable "runtime" {
  description = "Runtime environment for the Lambda function (required for Zip packages)"
  type        = string
  default     = null
}

# Source code options - either use filename OR s3_* variables OR image_uri
variable "filename" {
  description = "Path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Used to trigger updates when file contents change"
  type        = string
  default     = null
}

# For Container images
variable "image_uri" {
  description = "URI of the container image in Amazon ECR"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version of the function's deployment package"
  type        = string
  default     = null
}

# Function settings
variable "memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 3
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt environment variables"
  type        = string
  default     = null
}

# VPC config
variable "vpc_id" {
  description = "VPC ID to place the Lambda function in"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of additional security group IDs to associate with the Lambda function"
  type        = list(string)
  default     = []
}

# Environment variables
variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

# Permissions and policies
variable "lambda_role_name" {
  description = "Name of the IAM role to use for the Lambda function (e.g., 'LabRole')"
  type        = string
  default     = "LabRole"
}

variable "additional_policy_arns" {
  description = "List of IAM policy ARNs to attach to the Lambda function role"
  type        = list(string)
  default     = []
}

variable "create_api_gateway_permission" {
  description = "Whether to create API Gateway permission to invoke the Lambda function"
  type        = bool
  default     = false
}

variable "api_gateway_source_arn" {
  description = "ARN of the API Gateway that can invoke the Lambda function"
  type        = string
  default     = null
}

variable "additional_lambda_permissions" {
  description = "List of Lambda permissions for additional triggers"
  type = list(object({
    statement_id = string
    principal    = string
    source_arn   = optional(string)
  }))
  default = []
}

# Dead letter configuration
variable "dead_letter_target_arn" {
  description = "ARN of an SNS topic or SQS queue for failed executions"
  type        = string
  default     = null
}

# Tracing
variable "tracing_mode" {
  description = "X-Ray tracing mode (PassThrough or Active)"
  type        = string
  default     = null
  validation {
    condition     = var.tracing_mode == null || contains(["PassThrough", "Active"], var.tracing_mode)
    error_message = "Tracing mode must be either PassThrough or Active."
  }
}

# Logging
variable "log_retention_in_days" {
  description = "Number of days to retain Lambda logs in CloudWatch"
  type        = number
  default     = 14
}

variable "log_kms_key_id" {
  description = "The ARN of the KMS Key to use for encrypting Lambda logs"
  type        = string
  default     = null
}

# Alias configuration
variable "create_alias" {
  description = "Whether to create a Lambda alias"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "current"
}

variable "alias_description" {
  description = "Description of the Lambda alias"
  type        = string
  default     = "Current version alias"
}

variable "function_version" {
  description = "Version of the Lambda function to point the alias to"
  type        = string
  default     = null
}

# Routing config for canary deployments
variable "routing_additional_version" {
  description = "Version number of the additional version for weighted routing"
  type        = string
  default     = null
}

variable "routing_additional_version_weight" {
  description = "Weight percentage for the additional version in weighted routing"
  type        = number
  default     = null
}
