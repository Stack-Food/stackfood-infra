output "api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "invoke_url" {
  value = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  value = aws_apigatewayv2_api.this.execution_arn
}
