# Combine topic names and ARNs into a single list
locals {
  all_sns_topic_arns = concat(
    [for topic_name in var.allowed_sns_topic_names : "arn:aws:sns:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${topic_name}"],
    var.allowed_sns_topic_arns
  )
}
