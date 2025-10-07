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
