# Terraform Configuration for Cloudflare Provider
# This file should be included when using Cloudflare as DNS provider

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52.5"
    }
  }
}

# Note: The Cloudflare provider should be configured in your root module
# Example configuration:
#
# provider "cloudflare" {
#   api_token = var.cloudflare_api_token
# }
#
# Or using API key:
#
# provider "cloudflare" {
#   api_key   = var.cloudflare_api_key
#   email     = var.cloudflare_email
# }
