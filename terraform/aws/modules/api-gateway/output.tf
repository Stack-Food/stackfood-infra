# ID e ARN da API Gateway REST
output "api_gateway_id" {
  description = "The ID of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.arn
}

# Endpoint base da API
output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

# Stage info
output "api_gateway_stage_name" {
  description = "The stage name"
  value       = aws_api_gateway_stage.dev.stage_name
}

output "api_gateway_stage_invoke_url" {
  description = "The full invoke URL for the stage"
  value       = aws_api_gateway_stage.dev.invoke_url
}

# Lambda Permission info
output "customer_lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission"
  value       = aws_lambda_permission.customer_api_gateway_invoke.statement_id
}

output "auth_lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission"
  value       = aws_lambda_permission.auth_api_gateway_invoke.statement_id
}

# Custom domain (se estiver usando)
output "custom_domain_name" {
  description = "The custom domain name of the API Gateway"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "custom_domain_name_target_domain_name" {
  description = "The target domain name for the custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "custom_domain_name_hosted_zone_id" {
  description = "The hosted zone ID for the custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}

# VPC Link (caso esteja integrando com NLB no EKS)
output "vpc_link_id" {
  description = "The ID of the VPC Link"
  value       = aws_api_gateway_vpc_link.eks.id
}

output "vpc_link_arn" {
  description = "The ARN of the VPC Link"
  value       = aws_api_gateway_vpc_link.eks.arn
}

output "security_group_id" {
  description = "The ID of the VPC Link security group"
  value       = aws_security_group.vpc_link.id
}

# NLB debugging
output "nlb_dns_name" {
  description = "The DNS name of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].dns_name : null
}

output "nlb_arn" {
  description = "The ARN of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].arn : null
}

output "nlb_zone_id" {
  description = "The zone ID of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].zone_id : null
}
