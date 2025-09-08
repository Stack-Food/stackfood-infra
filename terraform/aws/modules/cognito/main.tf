##########################
# Cognito User Pool Module #
##########################

# CloudWatch Log Group for Cognito Logs
resource "aws_cloudwatch_log_group" "cognito" {
  name              = "/aws/cognito/userpool/${var.user_pool_name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "cognito-logs-${var.user_pool_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  # Alias Configuration - Para autenticação customizada por CPF
  # Se não usar username_attributes, usar alias_attributes para flexibilidade
  alias_attributes         = var.username_attributes == null ? var.alias_attributes : null
  auto_verified_attributes = var.auto_verified_attributes
  username_attributes      = var.username_attributes

  # User Pool Policies
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = var.password_require_lowercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    require_uppercase                = var.password_require_uppercase
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  # User Pool Lambda Config
  dynamic "lambda_config" {
    for_each = var.lambda_config != null ? [var.lambda_config] : []
    content {
      create_auth_challenge          = lambda_config.value.create_auth_challenge
      custom_message                 = lambda_config.value.custom_message
      define_auth_challenge          = lambda_config.value.define_auth_challenge
      post_authentication            = lambda_config.value.post_authentication
      post_confirmation              = lambda_config.value.post_confirmation
      pre_authentication             = lambda_config.value.pre_authentication
      pre_sign_up                    = lambda_config.value.pre_sign_up
      pre_token_generation           = lambda_config.value.pre_token_generation
      user_migration                 = lambda_config.value.user_migration
      verify_auth_challenge_response = lambda_config.value.verify_auth_challenge_response
    }
  }

  # Account Recovery Setting
  dynamic "account_recovery_setting" {
    for_each = var.recovery_mechanisms != null ? [1] : []
    content {
      dynamic "recovery_mechanism" {
        for_each = var.recovery_mechanisms
        content {
          name     = recovery_mechanism.value.name
          priority = recovery_mechanism.value.priority
        }
      }
    }
  }

  # Admin Create User Config
  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only

    dynamic "invite_message_template" {
      for_each = var.invite_message_template != null ? [var.invite_message_template] : []
      content {
        email_message = invite_message_template.value.email_message
        email_subject = invite_message_template.value.email_subject
        sms_message   = invite_message_template.value.sms_message
      }
    }
  }

  # Device Configuration
  dynamic "device_configuration" {
    for_each = var.device_configuration != null ? [var.device_configuration] : []
    content {
      challenge_required_on_new_device      = device_configuration.value.challenge_required_on_new_device
      device_only_remembered_on_user_prompt = device_configuration.value.device_only_remembered_on_user_prompt
    }
  }

  # Email Configuration
  dynamic "email_configuration" {
    for_each = var.email_configuration != null ? [var.email_configuration] : []
    content {
      configuration_set      = email_configuration.value.configuration_set
      email_sending_account  = email_configuration.value.email_sending_account
      from_email_address     = email_configuration.value.from_email_address
      reply_to_email_address = email_configuration.value.reply_to_email_address
      source_arn             = email_configuration.value.source_arn
    }
  }

  # SMS Configuration
  dynamic "sms_configuration" {
    for_each = var.sms_configuration != null ? [var.sms_configuration] : []
    content {
      external_id    = sms_configuration.value.external_id
      sns_caller_arn = sms_configuration.value.sns_caller_arn
      sns_region     = sms_configuration.value.sns_region
    }
  }

  # User Pool Add Ons
  dynamic "user_pool_add_ons" {
    for_each = var.advanced_security_mode != null ? [1] : []
    content {
      advanced_security_mode = var.advanced_security_mode
    }
  }

  # Verification Message Template
  dynamic "verification_message_template" {
    for_each = var.verification_message_template != null ? [var.verification_message_template] : []
    content {
      default_email_option  = verification_message_template.value.default_email_option
      email_message         = verification_message_template.value.email_message
      email_message_by_link = verification_message_template.value.email_message_by_link
      email_subject         = verification_message_template.value.email_subject
      email_subject_by_link = verification_message_template.value.email_subject_by_link
      sms_message           = verification_message_template.value.sms_message
    }
  }

  # User Attribute Update Settings
  dynamic "user_attribute_update_settings" {
    for_each = var.attributes_require_verification_before_update != null ? [1] : []
    content {
      attributes_require_verification_before_update = var.attributes_require_verification_before_update
    }
  }

  # Schema Configuration
  dynamic "schema" {
    for_each = var.schemas
    content {
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      name                     = schema.value.name
      required                 = schema.value.required

      dynamic "number_attribute_constraints" {
        for_each = schema.value.number_attribute_constraints != null ? [schema.value.number_attribute_constraints] : []
        content {
          max_value = number_attribute_constraints.value.max_value
          min_value = number_attribute_constraints.value.min_value
        }
      }

      dynamic "string_attribute_constraints" {
        for_each = schema.value.string_attribute_constraints != null ? [schema.value.string_attribute_constraints] : []
        content {
          max_length = string_attribute_constraints.value.max_length
          min_length = string_attribute_constraints.value.min_length
        }
      }
    }
  }

  tags = merge(
    {
      Name        = var.user_pool_name
      Environment = var.environment
    },
    var.tags
  )
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "this" {
  count           = var.domain != null ? 1 : 0
  domain          = var.domain
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.this.id
}

# Cognito User Pool Clients
resource "aws_cognito_user_pool_client" "this" {
  for_each = var.clients

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id

  # Client Settings
  generate_secret        = each.value.generate_secret
  refresh_token_validity = each.value.refresh_token_validity
  access_token_validity  = each.value.access_token_validity
  id_token_validity      = each.value.id_token_validity
  token_validity_units {
    access_token  = each.value.access_token_validity_units
    id_token      = each.value.id_token_validity_units
    refresh_token = each.value.refresh_token_validity_units
  }

  # OAuth Settings
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  callback_urls                        = each.value.callback_urls
  default_redirect_uri                 = each.value.default_redirect_uri
  logout_urls                          = each.value.logout_urls

  # Security Settings
  explicit_auth_flows                           = each.value.explicit_auth_flows
  supported_identity_providers                  = each.value.supported_identity_providers
  prevent_user_existence_errors                 = each.value.prevent_user_existence_errors
  enable_token_revocation                       = each.value.enable_token_revocation
  enable_propagate_additional_user_context_data = each.value.enable_propagate_additional_user_context_data

  # Read and Write Attributes
  read_attributes  = each.value.read_attributes
  write_attributes = each.value.write_attributes

  # Analytics Configuration
  dynamic "analytics_configuration" {
    for_each = each.value.analytics_configuration != null ? [each.value.analytics_configuration] : []
    content {
      application_arn  = analytics_configuration.value.application_arn
      application_id   = analytics_configuration.value.application_id
      external_id      = analytics_configuration.value.external_id
      role_arn         = analytics_configuration.value.role_arn
      user_data_shared = analytics_configuration.value.user_data_shared
    }
  }
}

# Cognito Identity Pool (if needed)
resource "aws_cognito_identity_pool" "this" {
  count                            = var.create_identity_pool ? 1 : 0
  identity_pool_name               = "${var.user_pool_name}-identity-pool"
  allow_unauthenticated_identities = var.allow_unauthenticated_identities
  allow_classic_flow               = var.allow_classic_flow

  dynamic "cognito_identity_providers" {
    for_each = var.create_identity_pool ? [1] : []
    content {
      client_id               = aws_cognito_user_pool_client.this[var.default_client_key].id
      provider_name           = aws_cognito_user_pool.this.endpoint
      server_side_token_check = true
    }
  }

  # Supported Login Providers
  supported_login_providers = var.supported_login_providers

  # SAML Provider ARNs
  saml_provider_arns = var.saml_provider_arns

  tags = merge(
    {
      Name        = "${var.user_pool_name}-identity-pool"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Roles for Identity Pool
resource "aws_iam_role" "authenticated" {
  count = var.create_identity_pool ? 1 : 0
  name  = "${var.user_pool_name}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.this[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.user_pool_name}-cognito-authenticated-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role" "unauthenticated" {
  count = var.create_identity_pool && var.allow_unauthenticated_identities ? 1 : 0
  name  = "${var.user_pool_name}-cognito-unauthenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.this[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.user_pool_name}-cognito-unauthenticated-role"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "authenticated" {
  count      = var.create_identity_pool ? 1 : 0
  role       = aws_iam_role.authenticated[0].name
  policy_arn = var.authenticated_role_policy_arn != null ? var.authenticated_role_policy_arn : "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

resource "aws_iam_role_policy_attachment" "unauthenticated" {
  count      = var.create_identity_pool && var.allow_unauthenticated_identities ? 1 : 0
  role       = aws_iam_role.unauthenticated[0].name
  policy_arn = var.unauthenticated_role_policy_arn != null ? var.unauthenticated_role_policy_arn : "arn:aws:iam::aws:policy/service-role/AmazonCognitoUnAuthRole"
}

# Identity Pool Role Attachment
resource "aws_cognito_identity_pool_roles_attachment" "this" {
  count            = var.create_identity_pool ? 1 : 0
  identity_pool_id = aws_cognito_identity_pool.this[0].id

  roles = merge(
    {
      "authenticated" = aws_iam_role.authenticated[0].arn
    },
    var.allow_unauthenticated_identities ? {
      "unauthenticated" = aws_iam_role.unauthenticated[0].arn
    } : {}
  )

  # Role mapping for fine-grained access
  dynamic "role_mapping" {
    for_each = var.role_mappings
    content {
      identity_provider         = role_mapping.value.identity_provider
      ambiguous_role_resolution = role_mapping.value.ambiguous_role_resolution
      type                      = role_mapping.value.type

      dynamic "mapping_rule" {
        for_each = role_mapping.value.mapping_rules != null ? role_mapping.value.mapping_rules : []
        content {
          claim      = mapping_rule.value.claim
          match_type = mapping_rule.value.match_type
          role_arn   = mapping_rule.value.role_arn
          value      = mapping_rule.value.value
        }
      }
    }
  }
}
