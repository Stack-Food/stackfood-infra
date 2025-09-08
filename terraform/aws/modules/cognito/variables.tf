######################
# Required Variables #
######################

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
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

# User Pool Configuration
variable "alias_attributes" {
  description = "Attributes supported as an alias for this user pool"
  type        = list(string)
  default     = null
}

variable "auto_verified_attributes" {
  description = "Attributes to be auto-verified"
  type        = list(string)
  default     = ["email"]
}

variable "username_attributes" {
  description = "Specifies whether email addresses or phone numbers can be specified as usernames"
  type        = list(string)
  default     = null
}

# Password Policy Configuration
variable "password_minimum_length" {
  description = "Minimum length of the password policy"
  type        = number
  default     = 8
}

variable "password_require_lowercase" {
  description = "Whether you have required users to use at least one lowercase letter in their password"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Whether you have required users to use at least one number in their password"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Whether you have required users to use at least one symbol in their password"
  type        = bool
  default     = true
}

variable "password_require_uppercase" {
  description = "Whether you have required users to use at least one uppercase letter in their password"
  type        = bool
  default     = true
}

variable "temporary_password_validity_days" {
  description = "Number of days a temporary password is valid"
  type        = number
  default     = 7
}

# Advanced Security
variable "advanced_security_mode" {
  description = "Mode for advanced security, must be one of OFF, AUDIT or ENFORCED"
  type        = string
  default     = "ENFORCED"

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "Advanced security mode must be one of: OFF, AUDIT, ENFORCED."
  }
}

# Admin Create User Configuration
variable "allow_admin_create_user_only" {
  description = "Set to True if only the administrator is allowed to create user profiles"
  type        = bool
  default     = false
}

variable "invite_message_template" {
  description = "Invite message template"
  type = object({
    email_message = optional(string)
    email_subject = optional(string)
    sms_message   = optional(string)
  })
  default = null
}

# Device Configuration
variable "device_configuration" {
  description = "Configuration for the user pool's device tracking"
  type = object({
    challenge_required_on_new_device      = optional(bool, false)
    device_only_remembered_on_user_prompt = optional(bool, false)
  })
  default = null
}

# Email Configuration
variable "email_configuration" {
  description = "Email configuration"
  type = object({
    configuration_set      = optional(string)
    email_sending_account  = optional(string, "COGNITO_DEFAULT")
    from_email_address     = optional(string)
    reply_to_email_address = optional(string)
    source_arn             = optional(string)
  })
  default = null
}

# SMS Configuration
variable "sms_configuration" {
  description = "SMS configuration"
  type = object({
    external_id    = optional(string)
    sns_caller_arn = string
    sns_region     = optional(string)
  })
  default = null
}

# Lambda Configuration
variable "lambda_config" {
  description = "Configuration for AWS Lambda triggers"
  type = object({
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
  })
  default = null
}

# Recovery Mechanisms
variable "recovery_mechanisms" {
  description = "List of recovery mechanisms"
  type = list(object({
    name     = string
    priority = number
  }))
  default = [
    {
      name     = "verified_email"
      priority = 1
    },
    {
      name     = "verified_phone_number"
      priority = 2
    }
  ]
}

# Verification Message Template
variable "verification_message_template" {
  description = "Verification message template configuration"
  type = object({
    default_email_option  = optional(string, "CONFIRM_WITH_CODE")
    email_message         = optional(string)
    email_message_by_link = optional(string)
    email_subject         = optional(string)
    email_subject_by_link = optional(string)
    sms_message           = optional(string)
  })
  default = null
}

# User Attribute Update Settings
variable "attributes_require_verification_before_update" {
  description = "A list of attributes requiring verification before update"
  type        = list(string)
  default     = ["email"]
}

# Schema Configuration
variable "schemas" {
  description = "A container with the schema attributes of a user pool"
  type = list(object({
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
  }))
  default = [
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
    },
    {
      attribute_data_type = "String"
      name                = "family_name"
      required            = false
      mutable             = true
      string_attribute_constraints = {
        min_length = "1"
        max_length = "256"
      }
    },
    {
      attribute_data_type = "String"
      name                = "phone_number"
      required            = false
      mutable             = true
      string_attribute_constraints = {
        min_length = "1"
        max_length = "256"
      }
    }
  ]
}

# Domain Configuration
variable "domain" {
  description = "Cognito User Pool domain"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of an ISSUED ACM certificate for custom domain"
  type        = string
  default     = null
}

# User Pool Clients Configuration
variable "clients" {
  description = "A container with the clients definitions"
  type = map(object({
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

    analytics_configuration = optional(object({
      application_arn  = optional(string)
      application_id   = optional(string)
      external_id      = optional(string)
      role_arn         = optional(string)
      user_data_shared = optional(bool, false)
    }))
  }))
  default = {}
}

# Identity Pool Configuration
variable "create_identity_pool" {
  description = "Whether to create Cognito Identity Pool"
  type        = bool
  default     = false
}

variable "allow_unauthenticated_identities" {
  description = "Whether the identity pool supports unauthenticated logins"
  type        = bool
  default     = false
}

variable "allow_classic_flow" {
  description = "Enables or disables the classic / basic authentication flow"
  type        = bool
  default     = false
}

variable "default_client_key" {
  description = "Default client key to use for identity pool"
  type        = string
  default     = "default"
}

variable "supported_login_providers" {
  description = "Key-Value pairs mapping provider names to provider app IDs"
  type        = map(string)
  default     = {}
}

variable "openid_connect_provider_arns" {
  description = "List of OpenID Connect provider ARNs"
  type        = list(string)
  default     = null
}

variable "saml_provider_arns" {
  description = "List of SAML provider ARNs"
  type        = list(string)
  default     = []
}

# IAM Role Configuration
variable "authenticated_role_policy_arn" {
  description = "ARN of the policy to attach to the authenticated role"
  type        = string
  default     = null
}

variable "unauthenticated_role_policy_arn" {
  description = "ARN of the policy to attach to the unauthenticated role"
  type        = string
  default     = null
}

# Role Mapping Configuration
variable "role_mappings" {
  description = "List of role mapping configurations"
  type = list(object({
    identity_provider         = string
    ambiguous_role_resolution = optional(string, "AuthenticatedRole")
    type                      = string

    mapping_rules = optional(list(object({
      claim      = string
      match_type = string
      role_arn   = string
      value      = string
    })))
  }))
  default = []
}
