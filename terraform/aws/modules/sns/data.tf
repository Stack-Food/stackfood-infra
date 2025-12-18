# =========================================
# DATA SOURCE: SQS Queue ARN lookup
# Looks up the SQS queue ARN by queue name (using the map key)
# =========================================
data "aws_sqs_queue" "subscription_queue" {
  for_each = var.sqs_subscriptions

  name = each.key
}

# =========================================
# DATA SOURCE: IAM Policy for SQS Queues
# This allows subscribed SQS queues to receive messages from the SNS topic
# =========================================
data "aws_iam_policy_document" "sqs_queue_policy" {
  for_each = var.sqs_subscriptions

  statement {
    sid    = "AllowSNSToSendMessages"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      data.aws_sqs_queue.subscription_queue[each.key].arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.topic.arn]
    }
  }
}
