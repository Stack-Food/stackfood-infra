# =========================================
# SNS TOPIC
# =========================================
resource "aws_sns_topic" "topic" {
  name = var.topic_name

  # Topic type - standard or FIFO
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  # Encryption
  kms_master_key_id = var.kms_master_key_id

  # Delivery policy (for retries)
  delivery_policy = var.delivery_policy != null ? jsonencode(var.delivery_policy) : null

  # Display name for SMS and email subscriptions
  display_name = var.display_name

  tags = merge(
    var.tags,
    {
      Name = var.topic_name
    }
  )
}

# =========================================
# SNS TOPIC POLICY (Optional)
# =========================================
resource "aws_sns_topic_policy" "policy" {
  count = var.topic_policy != null ? 1 : 0

  arn    = aws_sns_topic.topic.arn
  policy = can(jsonencode(var.topic_policy)) ? jsonencode(var.topic_policy) : var.topic_policy
}

# =========================================
# SQS QUEUE SUBSCRIPTIONS
# =========================================
resource "aws_sns_topic_subscription" "sqs_subscription" {
  for_each = var.sqs_subscriptions

  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = data.aws_sqs_queue.subscription_queue[each.key].arn

  # Optional subscription attributes
  raw_message_delivery = try(each.value.raw_message_delivery, false)
  filter_policy        = try(each.value.filter_policy, null) != null ? jsonencode(each.value.filter_policy) : null
  filter_policy_scope  = try(each.value.filter_policy_scope, null)
  redrive_policy       = try(each.value.redrive_policy, null) != null ? jsonencode(each.value.redrive_policy) : null
}

# =========================================
# EMAIL SUBSCRIPTIONS (Optional)
# =========================================
resource "aws_sns_topic_subscription" "email_subscription" {
  for_each = toset(var.email_subscriptions)

  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = each.value
}

# =========================================
# HTTPS SUBSCRIPTIONS (Optional)
# =========================================
resource "aws_sns_topic_subscription" "https_subscription" {
  for_each = var.https_subscriptions

  topic_arn = aws_sns_topic.topic.arn
  protocol  = "https"
  endpoint  = each.value.endpoint

  # Optional subscription attributes
  raw_message_delivery = try(each.value.raw_message_delivery, false)
  filter_policy        = try(each.value.filter_policy, null) != null ? jsonencode(each.value.filter_policy) : null
  filter_policy_scope  = try(each.value.filter_policy_scope, null)
  redrive_policy       = try(each.value.redrive_policy, null) != null ? jsonencode(each.value.redrive_policy) : null
}

# =========================================
# LAMBDA SUBSCRIPTIONS (Optional)
# =========================================
resource "aws_sns_topic_subscription" "lambda_subscription" {
  for_each = var.lambda_subscriptions

  topic_arn = aws_sns_topic.topic.arn
  protocol  = "lambda"
  endpoint  = each.value.function_arn

  # Optional subscription attributes
  filter_policy       = try(each.value.filter_policy, null) != null ? jsonencode(each.value.filter_policy) : null
  filter_policy_scope = try(each.value.filter_policy_scope, null)
  redrive_policy      = try(each.value.redrive_policy, null) != null ? jsonencode(each.value.redrive_policy) : null
}
