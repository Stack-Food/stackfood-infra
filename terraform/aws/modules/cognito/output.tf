# Cognito User Pool Outputs

output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "Name of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.name
}

output "user_pool_endpoint" {
  description = "Endpoint name of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.endpoint
}

output "user_pool_creation_date" {
  description = "Date the user pool was created"
  value       = aws_cognito_user_pool.this.creation_date
}

output "user_pool_last_modified_date" {
  description = "Date the user pool was last modified"
  value       = aws_cognito_user_pool.this.last_modified_date
}

output "user_pool_estimated_number_of_users" {
  description = "Estimated number of users in the user pool"
  value       = aws_cognito_user_pool.this.estimated_number_of_users
}

# User Pool Domain Outputs
output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = var.domain != null ? aws_cognito_user_pool_domain.this[0].domain : null
}

output "user_pool_hosted_ui_url" {
  description = "URL of the hosted UI"
  value       = var.domain != null ? "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${data.aws_region.current.region}.amazoncognito.com" : null
}

# User Pool Clients Outputster
output "user_pool_client_ids" {
  description = "Map of client names to their IDs"
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.id }
}

output "user_pool_client_secrets" {
  description = "Map of client names to their secrets"
  value       = { for k, v in aws_cognito_user_pool_client.this : k => v.client_secret if v.client_secret != null }
  sensitive   = true
}

output "user_pool_clients_details" {
  description = "Detailed information about user pool clients"
  value = { for k, v in aws_cognito_user_pool_client.this : k => {
    id                   = v.id
    name                 = v.name
    generate_secret      = v.generate_secret
    allowed_oauth_flows  = v.allowed_oauth_flows
    allowed_oauth_scopes = v.allowed_oauth_scopes
    callback_urls        = v.callback_urls
    logout_urls          = v.logout_urls
    explicit_auth_flows  = v.explicit_auth_flows
  } }
}

# Identity Pool Outputs (if created)
output "identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.this[0].id : null
}

output "identity_pool_arn" {
  description = "ARN of the Cognito Identity Pool"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.this[0].arn : null
}

output "identity_pool_name" {
  description = "Name of the Cognito Identity Pool"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.this[0].identity_pool_name : null
}

# IAM Roles Outputs (if Identity Pool is created)
output "authenticated_role_arn" {
  description = "ARN of the authenticated IAM role"
  value       = var.create_identity_pool ? aws_iam_role.authenticated[0].arn : null
}

output "unauthenticated_role_arn" {
  description = "ARN of the unauthenticated IAM role"
  value       = var.create_identity_pool && var.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[0].arn : null
}

# CloudWatch Log Group Outputs
output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cognito.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cognito.arn
}

# Regional Information
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Useful URLs and Endpoints
output "cognito_login_url" {
  description = "Cognito hosted UI login URL"
  value       = var.domain != null ? "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${data.aws_region.current.region}.amazoncognito.com/login" : null
}

output "cognito_logout_url" {
  description = "Cognito hosted UI logout URL"
  value       = var.domain != null ? "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${data.aws_region.current.region}.amazoncognito.com/logout" : null
}

# JWT Configuration for API Gateway
output "jwt_configuration" {
  description = "JWT configuration for API Gateway authorizers"
  value = {
    issuer   = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
    audience = [for k, v in aws_cognito_user_pool_client.this : v.id]
  }
}

# Summary Output
output "cognito_summary" {
  description = "Summary of the Cognito configuration"
  value = {
    user_pool_id      = aws_cognito_user_pool.this.id
    user_pool_name    = aws_cognito_user_pool.this.name
    domain            = var.domain
    clients_count     = length(var.clients)
    identity_pool_id  = var.create_identity_pool ? aws_cognito_identity_pool.this[0].id : null
    region            = data.aws_region.current.region
    account_id        = data.aws_caller_identity.current.account_id
    hosted_ui_enabled = var.domain != null
  }
}
