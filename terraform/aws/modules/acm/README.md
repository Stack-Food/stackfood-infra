# ACM Module

## Overview

This module creates and manages AWS Certificate Manager (ACM) SSL/TLS certificates with DNS validation for secure HTTPS communication across the StackFood infrastructure.

## Resources Created

- SSL/TLS certificates for primary and wildcard domains
- DNS validation records in Route 53 or external DNS
- Certificate validation and lifecycle management
- Multi-domain certificates with Subject Alternative Names (SAN)

## Architecture

```
ACM Certificates
├── Primary Certificate
│   ├── Domain: stackfood.com.br
│   ├── SAN: *.stackfood.com.br
│   └── DNS Validation
├── Certificate Validation
│   ├── CNAME Records
│   └── Validation Status
└── Integration Points
    ├── CloudFront
    ├── API Gateway
    ├── Load Balancer
    └── ArgoCD Ingress
```

## Inputs

| Variable                    | Type         | Description                        | Default  |
| --------------------------- | ------------ | ---------------------------------- | -------- |
| `domain_name`               | string       | Primary domain name                | required |
| `subject_alternative_names` | list(string) | Additional domains for certificate | []       |
| `validation_method`         | string       | Certificate validation method      | "DNS"    |
| `environment`               | string       | Environment name                   | required |
| `tags`                      | map(string)  | Resource tags                      | {}       |

## Outputs

| Output                      | Description                   |
| --------------------------- | ----------------------------- |
| `certificate_arn`           | ACM certificate ARN           |
| `certificate_domain_name`   | Primary domain name           |
| `certificate_status`        | Certificate validation status |
| `domain_validation_options` | DNS validation records        |

## Example Usage

```hcl
module "acm" {
  source = "../modules/acm/"

  domain_name = "stackfood.com.br"
  subject_alternative_names = [
    "*.stackfood.com.br",
    "api.stackfood.com.br",
    "argo.stackfood.com.br"
  ]

  validation_method = "DNS"
  environment      = "prod"

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- Wildcard certificate support for subdomains
- Automatic certificate renewal
- DNS validation for domain ownership
- Multi-domain certificates with SAN
- Integration with AWS services
- Certificate transparency logging

## Validation Process

1. **Certificate Request**: ACM creates certificate request
2. **DNS Validation**: CNAME records added to DNS provider
3. **Domain Verification**: ACM validates domain ownership
4. **Certificate Issuance**: Valid certificate issued and stored
5. **Auto-Renewal**: Automatic renewal before expiration

## Integration Points

### API Gateway

- Custom domain SSL termination
- Regional certificate deployment
- Domain name mapping

### Application Load Balancer

- HTTPS listeners configuration
- SSL policy management
- Certificate attachment

### CloudFront

- Edge locations SSL termination
- Global certificate distribution
- Custom domain configuration

## DNS Validation Records

```
_acme-challenge.stackfood.com.br CNAME
_validation.acm-validations.aws.
```

## Security

- RSA 2048-bit or ECDSA P-256 encryption
- TLS 1.2 and 1.3 protocol support
- Certificate transparency compliance
- Automated security patching
- Key rotation and management

## Monitoring

- Certificate expiration monitoring
- Validation status tracking
- Usage metrics across services
- CloudWatch alarms for renewal failures
- Certificate lifecycle notifications

## Best Practices

- Use wildcard certificates for multiple subdomains
- Implement certificate rotation policies
- Monitor certificate expiration dates
- Validate DNS configuration accuracy
- Test certificate deployment across environments
