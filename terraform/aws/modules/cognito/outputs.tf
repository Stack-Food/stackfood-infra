
###########################
# Outputs                 #
###########################

output "user_pool_id" {
  description = "ID do Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN do Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_client_id" {
  description = "ID do client do User Pool"
  value       = aws_cognito_user_pool_client.this.id
}

output "user_pool_endpoint" {
  description = "Endpoint do Cognito User Pool"
  value       = aws_cognito_user_pool.this.endpoint
}

# Configuração pronta para API Gateway Authorizer
output "api_gateway_authorizer_config" {
  description = "Configuração para authorizer do API Gateway"
  value = {
    type          = "COGNITO_USER_POOLS"
    user_pool_arn = aws_cognito_user_pool.this.arn
    user_pool_id  = aws_cognito_user_pool.this.id
    client_id     = aws_cognito_user_pool_client.this.id
  }
}
