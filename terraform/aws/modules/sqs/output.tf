output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "Same as queue_id: The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.this.url
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = aws_sqs_queue.this.name
}

output "queue_tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider"
  value       = aws_sqs_queue.this.tags_all
}

# Dead Letter Queue Outputs
output "dlq_id" {
  description = "The URL for the created Dead Letter Queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].id : null
}

output "dlq_arn" {
  description = "The ARN of the Dead Letter Queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "Same as dlq_id: The URL for the created Dead Letter Queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_name" {
  description = "The name of the Dead Letter Queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].name : null
}
