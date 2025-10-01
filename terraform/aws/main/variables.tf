######################
# General Variables #
######################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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
# Domain Configuration #
######################

variable "domain_name" {
  description = "The primary domain name for SSL certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Set of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for DNS validation"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token for DNS management"
  type        = string
  sensitive   = true
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
      availability_zone = "us-east-1a"
      cidr_block        = "10.0.1.0/24"
    },
    "private2" = {
      availability_zone = "us-east-1b"
      cidr_block        = "10.0.2.0/24"
    },
    "private3" = {
      availability_zone = "us-east-1c"
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
      availability_zone = "us-east-1a"
      cidr_block        = "10.0.101.0/24"
    },
    "public2" = {
      availability_zone = "us-east-1b"
      cidr_block        = "10.0.102.0/24"
    },
    "public3" = {
      availability_zone = "us-east-1c"
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
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
}

# EKS Remote Management Configuration
variable "eks_enable_remote_management" {
  description = "Whether to enable remote management access to the EKS cluster"
  type        = bool
}

variable "eks_management_cidr_blocks" {
  description = "List of CIDR blocks allowed for remote management access to EKS"
  type        = list(string)
}

variable "eks_authentication_mode" {
  description = "Authentication mode for EKS cluster (e.g., 'aws', 'oidc')"
  type        = string
}

variable "eks_log_retention_in_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "eks_log_kms_key_id" {
  description = "KMS key ID for encrypting EKS logs"
  type        = string
  default     = null
}

variable "eks_kms_key_arn" {
  description = "KMS key ARN for encrypting EKS resources"
  type        = string
  default     = null
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
  description = "Map of Lambda functions to create"
  type = map(object({
    description           = string
    package_type          = optional(string, "Zip")
    runtime               = optional(string)
    handler               = optional(string)
    filename              = optional(string)
    source_code_hash      = optional(string)
    image_uri             = optional(string)
    memory_size           = number
    timeout               = number
    vpc_access            = bool
    environment_variables = map(string)
  }))
  default = {}
}

######################
# IAM Configuration #
######################

variable "lambda_role_name" {
  description = "Name of the IAM role to use for Lambda functions"
  type        = string
}

variable "rds_role_name" {
  description = "Name of the IAM role to use for RDS enhanced monitoring (if needed)"
  type        = string
}

variable "eks_cluster_role_name" {
  description = "Name of the IAM role to use for the EKS cluster"
  type        = string
}

variable "eks_node_role_name" {
  description = "Name of the IAM role to use for the EKS node groups"
  type        = string
}

##########################
# API Gateway Configuration #
##########################

# variable "api_gateways" {
#   description = "API Gateways values"
# }
variable "api_gateways" {
  description = "Map of API Gateways to create"
}

##########################
# Cognito Configuration #
##########################

variable "cognito_user_pools" {
  description = "Map of Cognito User Pools to create"
  type = map(object({
    name                                          = string
    alias_attributes                              = optional(list(string), ["email"])
    auto_verified_attributes                      = optional(list(string), ["email"])
    username_attributes                           = optional(list(string), ["email"])
    attributes_require_verification_before_update = optional(list(string), null)

    # Password Policy
    password_minimum_length          = optional(number, 8)
    password_require_lowercase       = optional(bool, true)
    password_require_numbers         = optional(bool, true)
    password_require_symbols         = optional(bool, true)
    password_require_uppercase       = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)

    # Security Settings
    advanced_security_mode       = optional(string, "ENFORCED")
    allow_admin_create_user_only = optional(bool, false)

    # Communication Settings
    email_configuration = optional(object({
      configuration_set      = optional(string)
      email_sending_account  = optional(string, "COGNITO_DEFAULT")
      from_email_address     = optional(string)
      reply_to_email_address = optional(string)
      source_arn             = optional(string)
    }))

    sms_configuration = optional(object({
      external_id    = optional(string)
      sns_caller_arn = string
      sns_region     = optional(string)
    }))

    # Lambda Triggers
    lambda_config = optional(object({
      create_auth_challenge          = optional(string)
      custom_message                 = optional(string)
      define_auth_challenge          = optional(string)
      post_authentication            = optional(string)
      post_confirmation              = optional(string)
      pre_authentication             = optional(string)
      pre_sign_up                    = optional(string)
      pre_token_generation           = optional(string)
      user_migration                 = optional(string)
      verify_auth_challenge_response = optional(string)
    }))

    # Domain Configuration
    domain          = optional(string)
    certificate_arn = optional(string)

    # Client Applications
    clients = map(object({
      name                         = string
      generate_secret              = optional(bool, false)
      refresh_token_validity       = optional(number, 30)
      access_token_validity        = optional(number, 60)
      id_token_validity            = optional(number, 60)
      access_token_validity_units  = optional(string, "minutes")
      id_token_validity_units      = optional(string, "minutes")
      refresh_token_validity_units = optional(string, "days")

      allowed_oauth_flows                  = optional(list(string), ["code"])
      allowed_oauth_flows_user_pool_client = optional(bool, true)
      allowed_oauth_scopes                 = optional(list(string), ["email", "openid", "profile"])
      callback_urls                        = optional(list(string), [])
      default_redirect_uri                 = optional(string)
      logout_urls                          = optional(list(string), [])

      explicit_auth_flows                           = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_ADMIN_USER_PASSWORD_AUTH"])
      supported_identity_providers                  = optional(list(string), ["COGNITO"])
      prevent_user_existence_errors                 = optional(string, "ENABLED")
      enable_token_revocation                       = optional(bool, true)
      enable_propagate_additional_user_context_data = optional(bool, false)

      read_attributes  = optional(list(string), ["email", "name", "family_name", "phone_number"])
      write_attributes = optional(list(string), ["email", "name", "family_name", "phone_number"])
    }))

    # Identity Pool Configuration
    create_identity_pool             = optional(bool, false)
    allow_unauthenticated_identities = optional(bool, false)
    default_client_key               = optional(string, "default")
    supported_login_providers        = optional(map(string), {})

    # Custom Attributes Schema
    schemas = optional(list(object({
      attribute_data_type      = string
      developer_only_attribute = optional(bool, false)
      mutable                  = optional(bool, true)
      name                     = string
      required                 = optional(bool, false)

      number_attribute_constraints = optional(object({
        max_value = optional(string)
        min_value = optional(string)
      }))

      string_attribute_constraints = optional(object({
        max_length = optional(string)
        min_length = optional(string)
      }))
      })), [
      {
        attribute_data_type = "String"
        name                = "email"
        required            = true
        mutable             = true
        string_attribute_constraints = {
          min_length = "1"
          max_length = "256"
        }
      },
      {
        attribute_data_type = "String"
        name                = "name"
        required            = true
        mutable             = true
        string_attribute_constraints = {
          min_length = "1"
          max_length = "256"
        }
      }
    ])
  }))
  default = {}
}


######################
# NGINX Ingress Configuration #
######################

variable "nginx_ingress_name" {
  description = "Name of the NGINX Ingress Helm release"
  type        = string
}

variable "nginx_ingress_repository" {
  description = "Helm repository for the NGINX Ingress controller"
  type        = string
}

variable "nginx_ingress_chart" {
  description = "Helm chart name for the NGINX Ingress controller"
  type        = string
}

variable "nginx_ingress_namespace" {
  description = "Kubernetes namespace to deploy the NGINX Ingress controller"
  type        = string
}

variable "nginx_ingress_version" {
  description = "Version of the NGINX Ingress Helm chart"
  type        = string
}

