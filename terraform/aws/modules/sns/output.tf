# =========================================
# SNS TOPIC OUTPUTS
# =========================================

output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.topic.arn
}

output "topic_id" {
  description = "The ID of the SNS topic"
  value       = aws_sns_topic.topic.id
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.topic.name
}

output "topic_owner" {
  description = "The AWS account ID of the SNS topic owner"
  value       = aws_sns_topic.topic.owner
}

# =========================================
# SUBSCRIPTION OUTPUTS
# =========================================

output "sqs_subscription_arns" {
  description = "Map of SQS subscription names to their ARNs"
  value       = { for k, v in aws_sns_topic_subscription.sqs_subscription : k => v.arn }
}

output "email_subscription_arns" {
  description = "Map of email subscriptions to their ARNs"
  value       = { for k, v in aws_sns_topic_subscription.email_subscription : k => v.arn }
}

output "https_subscription_arns" {
  description = "Map of HTTPS subscription names to their ARNs"
  value       = { for k, v in aws_sns_topic_subscription.https_subscription : k => v.arn }
}

output "lambda_subscription_arns" {
  description = "Map of Lambda subscription names to their ARNs"
  value       = { for k, v in aws_sns_topic_subscription.lambda_subscription : k => v.arn }
}

# =========================================
# IAM POLICY DOCUMENT OUTPUTS
# =========================================

output "sqs_queue_policy_json" {
  description = "Map of SQS queue names to their IAM policy JSON documents allowing SNS to send messages"
  value       = { for k, v in data.aws_iam_policy_document.sqs_queue_policy : k => v.json }
}
