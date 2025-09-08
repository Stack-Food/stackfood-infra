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

variable "db_password" {
  description = "The password for the RDS database user"
  type        = string
  default     = "postgres"
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
  type = map(object({
    name                 = string
    description          = optional(string, "")
    stage_name           = string
    endpoint_type        = optional(string, "REGIONAL")
    enable_cors          = optional(bool, true)
    enable_access_logs   = optional(bool, true)
    xray_tracing_enabled = optional(bool, false)

    # CORS Configuration
    cors_allow_origins     = optional(list(string), ["*"])
    cors_allow_methods     = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    cors_allow_headers     = optional(list(string), ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"])
    cors_allow_credentials = optional(bool, false)

    # Throttling
    throttle_settings = optional(object({
      rate_limit  = number
      burst_limit = number
    }))

    # Caching
    cache_cluster_enabled = optional(bool, false)
    cache_cluster_size    = optional(string, "0.5")

    # Resources and Methods
    resources = optional(map(object({
      path_part = string
      parent_id = optional(string)
    })), {})

    methods = optional(map(object({
      resource_key         = optional(string)
      resource_id          = optional(string)
      http_method          = string
      authorization        = optional(string, "NONE")
      authorizer_id        = optional(string)
      authorization_scopes = optional(list(string))
      api_key_required     = optional(bool, false)
      operation_name       = optional(string)
      request_models       = optional(map(string))
      request_validator_id = optional(string)
      request_parameters   = optional(map(bool))
    })), {})

    integrations = optional(map(object({
      method_key              = string
      resource_key            = optional(string)
      resource_id             = optional(string)
      integration_http_method = string
      type                    = string
      uri                     = string
      connection_type         = optional(string)
      connection_id           = optional(string)
      credentials             = optional(string)
      request_templates       = optional(map(string))
      request_parameters      = optional(map(string))
      passthrough_behavior    = optional(string, "WHEN_NO_MATCH")
      cache_key_parameters    = optional(list(string))
      cache_namespace         = optional(string)
      content_handling        = optional(string)
      timeout_milliseconds    = optional(number, 29000)
      tls_config = optional(object({
        insecure_skip_verification = bool
      }))
    })), {})

    method_responses = optional(map(object({
      method_key          = string
      resource_key        = optional(string)
      resource_id         = optional(string)
      status_code         = string
      response_models     = optional(map(string))
      response_parameters = optional(map(bool))
    })), {})

    integration_responses = optional(map(object({
      method_key          = string
      method_response_key = string
      resource_key        = optional(string)
      resource_id         = optional(string)
      response_templates  = optional(map(string))
      response_parameters = optional(map(string))
      selection_pattern   = optional(string)
      content_handling    = optional(string)
    })), {})

    # API Keys and Usage Plans
    api_keys = optional(map(object({
      name        = string
      description = optional(string)
      enabled     = optional(bool, true)
    })), {})

    usage_plans = optional(map(object({
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
    })), {})

    usage_plan_keys = optional(map(object({
      api_key    = string
      usage_plan = string
    })), {})

    # Lambda Permissions
    lambda_permissions = optional(map(object({
      statement_id  = string
      function_name = string
      qualifier     = optional(string)
    })), {})
  }))
  default = {}
}

##########################
# Cognito Configuration #
##########################

variable "cognito_user_pools" {
  description = "Map of Cognito User Pools to create"
  type = map(object({
    name                     = string
    alias_attributes         = optional(list(string), ["email"])
    auto_verified_attributes = optional(list(string), ["email"])
    username_attributes      = optional(list(string), ["email"])

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
