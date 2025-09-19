######################
# Required Variables #
######################

variable "domain_name" {
  description = "The domain name for which the certificate should be issued"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

######################
# Optional Variables #
######################

variable "subject_alternative_names" {
  description = "Set of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Which method to use for validation"
  type        = string
  default     = "DNS"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for DNS validation"
  type        = string
}

variable "key_algorithm" {
  description = "Specifies the algorithm of the public and private key pair"
  type        = string
  default     = "RSA_2048"
}

variable "transparency_logging_preference" {
  description = "Specifies whether certificate details should be added to a certificate transparency log"
  type        = string
  default     = "ENABLED"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
