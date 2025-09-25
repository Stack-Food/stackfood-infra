# Certificate Outputs
output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "The domain name for which the certificate is issued"
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.this.status
}

output "certificate_subject_alternative_names" {
  description = "Set of domains that are SANs in the issued certificate"
  value       = aws_acm_certificate.this.subject_alternative_names
}

output "certificate_validation_emails" {
  description = "List of addresses that received a validation email"
  value       = aws_acm_certificate.this.validation_emails
}

output "certificate_validation_method" {
  description = "Validation method used for the certificate"
  value       = aws_acm_certificate.this.validation_method
}
# Validation Outputs
output "domain_validation_options" {
  description = "Set of domain validation objects which can be used to complete certificate validation"
  value       = aws_acm_certificate.this.domain_validation_options
  sensitive   = false
}


output "certificate_validation_arn" {
  description = "The ARN of the validated certificate"
  value       = aws_acm_certificate.this.arn
}
