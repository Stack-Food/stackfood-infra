######################
# DynamoDB Outputs #
######################

output "table_id" {
  description = "The name/ID of the DynamoDB table"
  value       = aws_dynamodb_table.this.id
}

output "table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.arn
}

output "table_stream_arn" {
  description = "The ARN of the DynamoDB table stream (if enabled)"
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_arn : null
}

output "table_stream_label" {
  description = "The timestamp of when the stream was enabled"
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_label : null
}

output "hash_key" {
  description = "The partition key of the table"
  value       = aws_dynamodb_table.this.hash_key
}

output "range_key" {
  description = "The sort key of the table"
  value       = aws_dynamodb_table.this.range_key
}

output "billing_mode" {
  description = "The billing mode of the table"
  value       = aws_dynamodb_table.this.billing_mode
}

output "read_capacity" {
  description = "The read capacity of the table"
  value       = var.billing_mode == "PROVISIONED" ? aws_dynamodb_table.this.read_capacity : null
}

output "write_capacity" {
  description = "The write capacity of the table"
  value       = var.billing_mode == "PROVISIONED" ? aws_dynamodb_table.this.write_capacity : null
}

output "global_secondary_indexes" {
  description = "List of global secondary index names"
  value       = var.global_secondary_indexes != null ? [for gsi in var.global_secondary_indexes : gsi.name] : []
}

output "local_secondary_indexes" {
  description = "List of local secondary index names"
  value       = var.local_secondary_indexes != null ? [for lsi in var.local_secondary_indexes : lsi.name] : []
}

output "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled"
  value       = var.point_in_time_recovery_enabled
}

output "encryption_enabled" {
  description = "Whether server-side encryption is enabled"
  value       = var.encryption_enabled
}

output "kms_key_arn" {
  description = "The KMS key ARN used for encryption"
  value       = var.kms_key_arn
}

output "table_class" {
  description = "The storage class of the table"
  value       = aws_dynamodb_table.this.table_class
}
