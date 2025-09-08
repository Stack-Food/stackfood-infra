# # API Gateway Outputs

# # API Gateway REST API Outputs
# output "api_id" {
#   description = "ID of the REST API"
#   value       = aws_api_gateway_rest_api.this.id
# }

# output "api_arn" {
#   description = "ARN of the REST API"
#   value       = aws_api_gateway_rest_api.this.arn
# }

# output "api_name" {
#   description = "Name of the REST API"
#   value       = aws_api_gateway_rest_api.this.name
# }

# output "root_resource_id" {
#   description = "Root resource ID of the REST API"
#   value       = aws_api_gateway_rest_api.this.root_resource_id
# }

# output "execution_arn" {
#   description = "Execution ARN part to be used in lambda_permission's source_arn"
#   value       = aws_api_gateway_rest_api.this.execution_arn
# }

# output "created_date" {
#   description = "Creation date of the REST API"
#   value       = aws_api_gateway_rest_api.this.created_date
# }

# # Deployment Outputs
# output "deployment_id" {
#   description = "ID of the deployment"
#   value       = aws_api_gateway_deployment.this.id
# }

# output "deployment_invoke_url" {
#   description = "URL to invoke the API pointing to the stage"
#   value       = aws_api_gateway_deployment.this.invoke_url
# }

# # Stage Outputs
# output "stage_arn" {
#   description = "ARN of the stage"
#   value       = var.create_stage ? aws_api_gateway_stage.this[0].arn : null
# }

# output "stage_invoke_url" {
#   description = "URL to invoke the API pointing to the stage"
#   value       = var.create_stage ? aws_api_gateway_stage.this[0].invoke_url : null
# }

# output "stage_execution_arn" {
#   description = "Execution ARN of the stage"
#   value       = var.create_stage ? aws_api_gateway_stage.this[0].execution_arn : null
# }

# # Resources Outputs
# output "resource_ids" {
#   description = "Map of resource names to their IDs"
#   value       = { for k, v in aws_api_gateway_resource.this : k => v.id }
# }

# output "resource_paths" {
#   description = "Map of resource names to their paths"
#   value       = { for k, v in aws_api_gateway_resource.this : k => v.path }
# }

# # Methods Outputs
# output "method_ids" {
#   description = "Map of method keys to their HTTP methods"
#   value       = { for k, v in aws_api_gateway_method.this : k => v.http_method }
# }

# # CloudWatch Log Group Outputs
# output "log_group_name" {
#   description = "Name of the CloudWatch Log Group"
#   value       = aws_cloudwatch_log_group.api_gateway.name
# }

# output "log_group_arn" {
#   description = "ARN of the CloudWatch Log Group"
#   value       = aws_cloudwatch_log_group.api_gateway.arn
# }

# # API Keys Outputs
# output "api_key_ids" {
#   description = "Map of API key names to their IDs"
#   value       = { for k, v in aws_api_gateway_api_key.this : k => v.id }
# }

# output "api_key_values" {
#   description = "Map of API key names to their values"
#   value       = { for k, v in aws_api_gateway_api_key.this : k => v.value }
#   sensitive   = true
# }

# # Usage Plans Outputs
# output "usage_plan_ids" {
#   description = "Map of usage plan names to their IDs"
#   value       = { for k, v in aws_api_gateway_usage_plan.this : k => v.id }
# }

# output "usage_plan_arns" {
#   description = "Map of usage plan names to their ARNs"
#   value       = { for k, v in aws_api_gateway_usage_plan.this : k => v.arn }
# }

# # Integration Information
# output "integration_uris" {
#   description = "Map of integration keys to their URIs"
#   value       = { for k, v in var.integrations : k => v.uri }
# }

# # Complete API Information
# output "api_endpoint" {
#   description = "Complete API endpoint URL"
#   value       = var.create_stage ? "${aws_api_gateway_deployment.this.invoke_url}" : "${aws_api_gateway_rest_api.this.execution_arn}"
# }

# output "api_base_url" {
#   description = "Base URL for API Gateway stage"
#   value       = var.create_stage ? "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}" : null
# }

# # Regional Information (needed for API base URL)
# data "aws_region" "current" {}

# # Summary Output for Documentation
# output "api_summary" {
#   description = "Summary of the created API Gateway"
#   value = {
#     api_name     = aws_api_gateway_rest_api.this.name
#     api_id       = aws_api_gateway_rest_api.this.id
#     stage_name   = var.stage_name
#     endpoint_url = var.create_stage ? aws_api_gateway_stage.this[0].invoke_url : aws_api_gateway_deployment.this.invoke_url
#     resources    = length(var.resources)
#     methods      = length(var.methods)
#     integrations = length(var.integrations)
#     api_keys     = length(var.api_keys)
#     usage_plans  = length(var.usage_plans)
#   }
# }
