variable "queue_name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "fifo_queue" {
  description = "Boolean to indicate if the queue is FIFO"
  type        = bool
  default     = true
}

variable "queue_name_prefix" {
  description = "The prefix to use for the queue name"
  type        = string
  default     = null
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = true
}

variable "deduplication_scope" {
  description = "The scope of deduplication for FIFO queues"
  type        = string
  default     = "messageGroup"
}

variable "fifo_throughput_limit" {
  description = "The throughput limit for FIFO queues"
  type        = string
  default     = "perMessageGroupId"
}
variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 1048576
}
variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 345600
}

variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive"
  type        = number
  default     = 0
}

variable "redrive_allow_policy" {
  description = "The redrive allow policy (can be a JSON string or object)"
  type        = any
  default     = null
}

variable "redrive_policy" {
  description = "The redrive policy for the queue. Can be a JSON string or an object. Will be automatically encoded to JSON if provided as an object."
  type        = any
  default     = null
}

variable "sqs_managed_sse_enabled" {
  description = "Specifies whether to enable server-side encryption with SQS-managed encryption keys"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "enable_backup_tagging" {
  description = "Enable tagging for backups"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 30
}

variable "policy" {
  description = "The policy JSON to apply to the SQS queue (can be a JSON string or object)"
  type        = any
  default     = null
}

variable "create_default_policy" {
  description = "Whether to create a default policy that allows account root full access"
  type        = bool
  default     = true
}

variable "allowed_sns_topic_names" {
  description = "List of SNS topic names that are allowed to send messages to this queue"
  type        = list(string)
  default     = []
}

variable "allowed_sns_topic_arns" {
  description = "List of SNS topic ARNs that are allowed to send messages to this queue"
  type        = list(string)
  default     = []
}

variable "allowed_lambda_function_names" {
  description = "List of Lambda function names (IAM role names) that are allowed to access this queue"
  type        = list(string)
  default     = []
}

variable "allowed_lambda_function_arns" {
  description = "List of Lambda function ARNs that are allowed to access this queue"
  type        = list(string)
  default     = []
}

variable "create_dlq" {
  description = "Whether to create a Dead Letter Queue (DLQ)"
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "The name of the Dead Letter Queue"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "The maximum number of times a message can be received before being sent to the dead-letter queue"
  type        = number
  default     = 5
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again"
  type        = number
  default     = 300
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the dead-letter queue"
  type        = number
  default     = 1209600
}

# DLQ Specific Configuration Object
variable "dlq_config" {
  description = "Configuration object for Dead Letter Queue specific settings"
  type = object({
    delay_seconds                     = optional(number, 0)
    max_message_size                  = optional(number, 262144)
    message_retention_seconds         = optional(number, 1209600)
    receive_wait_time_seconds         = optional(number, 0)
    visibility_timeout_seconds        = optional(number, 30)
    sqs_managed_sse_enabled           = optional(bool, true)
    kms_master_key_id                 = optional(string, null)
    kms_data_key_reuse_period_seconds = optional(number, 300)
    content_based_deduplication       = optional(bool, null)
    deduplication_scope               = optional(string, null)
    fifo_throughput_limit             = optional(string, null)
    redrive_allow_policy              = optional(any, null)
    policy                            = optional(any, null)
    tags                              = optional(map(string), {})
  })
  default = null
}
