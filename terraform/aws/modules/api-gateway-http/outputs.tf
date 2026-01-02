output "api_id" {
  description = "ID da API Gateway HTTP"
  value       = aws_apigatewayv2_api.this.id
}

output "invoke_url" {
  description = "URL de invocação da API Gateway"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "ARN de execução da API Gateway"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "vpc_link_id" {
  description = "ID do VPC Link para integração com NLB"
  value       = aws_apigatewayv2_vpc_link.this.id
}

output "lambda_integration_enabled" {
  description = "Indica se a integração Lambda está habilitada"
  value       = var.enable_lambda_integration
}

output "auth_route_id" {
  description = "ID da rota /auth (se habilitada)"
  value       = var.enable_lambda_integration ? aws_apigatewayv2_route.auth_post[0].id : null
}

output "customer_route_id" {
  description = "ID da rota /customer (se habilitada)"
  value       = var.enable_lambda_integration ? aws_apigatewayv2_route.customer_post[0].id : null
}
