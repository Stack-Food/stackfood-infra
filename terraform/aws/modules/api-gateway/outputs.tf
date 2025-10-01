output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway"
  value       = aws_apigatewayv2_api.main.arn
}

output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway"
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "api_gateway_endpoint" {
  description = "The endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_stage_id" {
  description = "The ID of the API Gateway stage"
  value       = aws_apigatewayv2_stage.this.id
}

output "api_gateway_stage_arn" {
  description = "The ARN of the API Gateway stage"
  value       = aws_apigatewayv2_stage.this.arn
}

output "api_gateway_stage_invoke_url" {
  description = "The invoke URL of the API Gateway stage"
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "custom_domain_name" {
  description = "The custom domain name of the API Gateway"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.this[0].domain_name : null
}

output "custom_domain_name_target_domain_name" {
  description = "The target domain name for the custom domain"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name : null
}

output "custom_domain_name_hosted_zone_id" {
  description = "The hosted zone ID for the custom domain"
  value       = var.custom_domain_name != "" ? aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id : null
}

output "vpc_link_id" {
  description = "The ID of the VPC Link"
  value       = aws_apigatewayv2_vpc_link.eks.id
}

output "vpc_link_arn" {
  description = "The ARN of the VPC Link"
  value       = aws_apigatewayv2_vpc_link.eks.arn
}

output "security_group_id" {
  description = "The ID of the VPC Link security group"
  value       = aws_security_group.vpc_link.id
}
