# Get current AWS account ID and region for dynamic policy generation
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Default SQS queue policy - allows account root full access
data "aws_iam_policy_document" "default_policy" {
  count = var.policy == null && var.create_default_policy ? 1 : 0

  statement {
    sid    = "__owner_statement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.queue_name}"]
  }
}

# SNS to SQS policy - allows SNS topics to send messages to the queue
data "aws_iam_policy_document" "sns_policy" {
  count = length(local.all_sns_topic_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowSNSAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.queue_name}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = local.all_sns_topic_arns
    }
  }
}

# Lambda to SQS policy - allows Lambda functions to access the queue
data "aws_iam_policy_document" "lambda_policy" {
  count = length(var.allowed_lambda_function_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowLambdaAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.allowed_lambda_function_arns
    }

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.queue_name}"]
  }
}

# Combined policy document that merges all enabled policies
data "aws_iam_policy_document" "combined_policy" {
  count = var.policy == null && (var.create_default_policy || length(local.all_sns_topic_arns) > 0 || length(var.allowed_lambda_function_arns) > 0) ? 1 : 0

  source_policy_documents = compact([
    var.create_default_policy ? data.aws_iam_policy_document.default_policy[0].json : null,
    length(local.all_sns_topic_arns) > 0 ? data.aws_iam_policy_document.sns_policy[0].json : null,
    length(var.allowed_lambda_function_arns) > 0 ? data.aws_iam_policy_document.lambda_policy[0].json : null
  ])
}

# =========================================
# DLQ POLICY DOCUMENTS
# =========================================

# Default DLQ policy - allows account root full access to DLQ
data "aws_iam_policy_document" "dlq_default_policy" {
  count = var.create_dlq && (var.dlq_config == null || var.dlq_config.policy == null) && var.create_default_policy ? 1 : 0

  statement {
    sid    = "__owner_statement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.dlq_name != null ? var.dlq_name : "${var.queue_name}-dlq"}"]
  }
}

# SNS to DLQ policy - allows SNS topics to send messages to the DLQ
data "aws_iam_policy_document" "dlq_sns_policy" {
  count = var.create_dlq && (var.dlq_config == null || var.dlq_config.policy == null) && length(local.all_sns_topic_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowSNSAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.dlq_name != null ? var.dlq_name : "${var.queue_name}-dlq"}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = local.all_sns_topic_arns
    }
  }
}

# Lambda to DLQ policy - allows Lambda functions to access the DLQ
data "aws_iam_policy_document" "dlq_lambda_policy" {
  count = var.create_dlq && (var.dlq_config == null || var.dlq_config.policy == null) && length(var.allowed_lambda_function_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowLambdaAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.allowed_lambda_function_arns
    }

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.dlq_name != null ? var.dlq_name : "${var.queue_name}-dlq"}"]
  }
}

# Combined DLQ policy document that merges all enabled DLQ policies
data "aws_iam_policy_document" "dlq_combined_policy" {
  count = var.create_dlq && (var.dlq_config == null || var.dlq_config.policy == null) && (var.create_default_policy || length(local.all_sns_topic_arns) > 0 || length(var.allowed_lambda_function_arns) > 0) ? 1 : 0

  source_policy_documents = compact([
    var.create_default_policy ? data.aws_iam_policy_document.dlq_default_policy[0].json : null,
    length(local.all_sns_topic_arns) > 0 ? data.aws_iam_policy_document.dlq_sns_policy[0].json : null,
    length(var.allowed_lambda_function_arns) > 0 ? data.aws_iam_policy_document.dlq_lambda_policy[0].json : null
  ])
}
