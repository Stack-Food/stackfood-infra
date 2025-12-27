# =========================================
# REQUIRED VARIABLES
# =========================================

variable "topic_name" {
  description = "The name of the SNS topic"
  type        = string
}

# =========================================
# OPTIONAL VARIABLES
# =========================================

variable "fifo_topic" {
  description = "Whether the topic is a FIFO topic. If true, the topic name must end with .fifo"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO topics"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "The SNS delivery policy as a map. Will be converted to JSON"
  type        = any
  default     = null
}

variable "display_name" {
  description = "The display name for the topic (used in SMS and email)"
  type        = string
  default     = null
}

variable "topic_policy" {
  description = "The fully-formed AWS policy as JSON or a map that will be converted to JSON"
  type        = any
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the SNS topic"
  type        = map(string)
  default     = {}
}

# =========================================
# SUBSCRIPTION VARIABLES
# =========================================

variable "sqs_subscriptions" {
  description = <<-EOT
    A map of SQS queue subscriptions to create.
    The key should be the SQS queue name (ARN will be looked up automatically).
    Each entry can include:
    - raw_message_delivery: (Optional) Whether to enable raw message delivery (default: false)
    - filter_policy: (Optional) A map for filtering messages
    - filter_policy_scope: (Optional) MessageAttributes or MessageBody
    - redrive_policy: (Optional) JSON policy for DLQ redrive
  EOT
  type = map(object({
    raw_message_delivery = optional(bool)
    filter_policy        = optional(any)
    filter_policy_scope  = optional(string)
    redrive_policy       = optional(any)
  }))
  default = {}
}

variable "email_subscriptions" {
  description = "A list of email addresses to subscribe to the topic"
  type        = list(string)
  default     = []
}

variable "https_subscriptions" {
  description = <<-EOT
    A map of HTTPS endpoint subscriptions to create.
    Each entry should include:
    - endpoint: The HTTPS endpoint URL
    - raw_message_delivery: (Optional) Whether to enable raw message delivery
    - filter_policy: (Optional) A map for filtering messages
    - filter_policy_scope: (Optional) MessageAttributes or MessageBody
    - redrive_policy: (Optional) JSON policy for DLQ redrive
  EOT
  type = map(object({
    endpoint             = string
    raw_message_delivery = optional(bool)
    filter_policy        = optional(any)
    filter_policy_scope  = optional(string)
    redrive_policy       = optional(any)
  }))
  default = {}
}

variable "lambda_subscriptions" {
  description = <<-EOT
    A map of Lambda function subscriptions to create.
    Each entry should include:
    - function_arn: The ARN of the Lambda function
    - filter_policy: (Optional) A map for filtering messages
    - filter_policy_scope: (Optional) MessageAttributes or MessageBody
    - redrive_policy: (Optional) JSON policy for DLQ redrive
  EOT
  type = map(object({
    function_arn        = string
    filter_policy       = optional(any)
    filter_policy_scope = optional(string)
    redrive_policy      = optional(any)
  }))
  default = {}
}
