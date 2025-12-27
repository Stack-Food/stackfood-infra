# =========================================
# DEAD LETTER QUEUE (Optional)
# =========================================
resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name       = var.dlq_name != null ? var.dlq_name : "${var.queue_name}-dlq"
  fifo_queue = var.fifo_queue

  # DLQ-specific configurations with fallback to main queue or default values
  delay_seconds                     = var.dlq_config != null ? var.dlq_config.delay_seconds : var.delay_seconds
  max_message_size                  = var.dlq_config != null ? var.dlq_config.max_message_size : var.max_message_size
  message_retention_seconds         = var.dlq_config != null ? var.dlq_config.message_retention_seconds : var.dlq_message_retention_seconds
  receive_wait_time_seconds         = var.dlq_config != null ? var.dlq_config.receive_wait_time_seconds : var.receive_wait_time_seconds
  visibility_timeout_seconds        = var.dlq_config != null ? var.dlq_config.visibility_timeout_seconds : var.visibility_timeout_seconds
  sqs_managed_sse_enabled           = var.dlq_config != null ? var.dlq_config.sqs_managed_sse_enabled : var.sqs_managed_sse_enabled
  kms_master_key_id                 = var.dlq_config != null ? var.dlq_config.kms_master_key_id : var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.dlq_config != null && var.dlq_config.kms_master_key_id != null ? var.dlq_config.kms_data_key_reuse_period_seconds : (var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null)

  # FIFO-specific attributes for DLQ
  content_based_deduplication = var.fifo_queue ? (var.dlq_config != null && var.dlq_config.content_based_deduplication != null ? var.dlq_config.content_based_deduplication : var.content_based_deduplication) : null
  deduplication_scope         = var.fifo_queue ? (var.dlq_config != null && var.dlq_config.deduplication_scope != null ? var.dlq_config.deduplication_scope : var.deduplication_scope) : null
  fifo_throughput_limit       = var.fifo_queue ? (var.dlq_config != null && var.dlq_config.fifo_throughput_limit != null ? var.dlq_config.fifo_throughput_limit : var.fifo_throughput_limit) : null

  # DLQ-specific redrive allow policy
  redrive_allow_policy = var.dlq_config != null && var.dlq_config.redrive_allow_policy != null ? jsonencode(var.dlq_config.redrive_allow_policy) : null

  # DLQ-specific policy - follows same logic as main queue
  policy = var.dlq_config != null && var.dlq_config.policy != null ? (
    can(jsonencode(var.dlq_config.policy)) ? jsonencode(var.dlq_config.policy) : var.dlq_config.policy
    ) : coalesce(
    length(data.aws_iam_policy_document.dlq_combined_policy) > 0 ? data.aws_iam_policy_document.dlq_combined_policy[0].json : null
  )

  tags = merge(
    var.tags,
    var.dlq_config != null ? var.dlq_config.tags : {},
    {
      Name = var.dlq_name != null ? var.dlq_name : "${var.queue_name}-dlq"
      Type = "dead-letter-queue"
    },
    var.enable_backup_tagging ? {
      "aws-backup" = "true"
    } : {}
  )
}

# =========================================
# MAIN SQS QUEUE
# =========================================
resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  name_prefix                = var.queue_name_prefix
  visibility_timeout_seconds = var.visibility_timeout_seconds
  delay_seconds              = var.delay_seconds
  fifo_queue                 = var.fifo_queue
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  sqs_managed_sse_enabled    = var.sqs_managed_sse_enabled
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # FIFO-specific attributes (only applied when fifo_queue = true)
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? var.deduplication_scope : null
  fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

  # KMS encryption
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  # Redrive policy for DLQ
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  # Policies - use provided policy or generate default/combined policy
  policy = coalesce(
    var.policy,
    length(data.aws_iam_policy_document.combined_policy) > 0 ? data.aws_iam_policy_document.combined_policy[0].json : null
  )

  redrive_allow_policy = var.redrive_allow_policy != null ? jsonencode(var.redrive_allow_policy) : null

  tags = merge(
    var.tags,
    {
      Name = var.queue_name
    },
    var.enable_backup_tagging ? {
      "aws-backup" = "true"
    } : {}
  )
}
