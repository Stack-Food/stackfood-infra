# Lambda Outputs

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "ARN identifying your Lambda function version"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "security_group_id" {
  description = "ID of the security group created for the Lambda function (if deployed in VPC)"
  value       = length(var.subnet_ids) > 0 ? aws_security_group.lambda[0].id : null
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

