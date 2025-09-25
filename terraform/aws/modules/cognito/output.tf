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

output "user_pool_id" {
  description = "Configuração para authorizer do API Gateway"
  value       = aws_cognito_user_pool.this.id
}
