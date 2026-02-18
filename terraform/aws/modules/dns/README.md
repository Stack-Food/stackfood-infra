# DNS Module

## Overview

This module manages DNS records using Cloudflare as the DNS provider, creating and maintaining domain records for the OptimusFrame infrastructure with CDN and security features.

## Resources Created

- A records pointing to AWS resources
- CNAME records for service aliases
- TXT records for domain verification
- Cloudflare proxy configuration
- SSL/TLS encryption settings
- Page rules and security policies

## Architecture

```
Cloudflare DNS
├── Zone: optimus-frame.com.br
├── Records
│   ├── A @ → API Gateway
│   ├── A api → API Gateway
│   ├── A argo → EKS Load Balancer
│   └── CNAME www → optimus-frame.com.br
├── Proxy Configuration
│   ├── CDN Caching
│   ├── DDoS Protection
│   └── WAF Rules
└── SSL Settings
    ├── Full SSL
    ├── HSTS Headers
    └── TLS 1.3
```

## Inputs

| Variable               | Type        | Description                               | Default  |
| ---------------------- | ----------- | ----------------------------------------- | -------- |
| `cloudflare_zone_id`   | string      | Cloudflare zone ID                        | required |
| `domain_name`          | string      | Primary domain name                       | required |
| `environment`          | string      | Environment name                          | required |
| `eks_cluster_name`     | string      | EKS cluster name for load balancer lookup | required |
| `create_argocd_record` | bool        | Create ArgoCD DNS record                  | false    |
| `argocd_subdomain`     | string      | ArgoCD subdomain                          | "argo"   |
| `proxied`              | bool        | Enable Cloudflare proxy                   | true     |
| `ttl`                  | number      | DNS TTL in seconds                        | 300      |
| `tags`                 | map(string) | Resource tags                             | {}       |

## DNS Records Configuration

| Record Type | Name | Target            | Purpose          |
| ----------- | ---- | ----------------- | ---------------- |
| A           | @    | API Gateway IP    | Main domain      |
| A           | api  | API Gateway IP    | API endpoint     |
| A           | argo | EKS Load Balancer | ArgoCD interface |
| CNAME       | www  | optimus-frame.com.br  | WWW redirect     |

## Outputs

| Output                 | Description                |
| ---------------------- | -------------------------- |
| `dns_records`          | Map of created DNS records |
| `cloudflare_zone_info` | Zone configuration details |
| `argocd_dns_record`    | ArgoCD DNS record details  |

## Example Usage

```hcl
module "dns" {
  source = "../modules/dns/"

  cloudflare_zone_id = "09f31a057e454d7d71ab44b6b5960723"
  domain_name        = "optimus-frame.com.br"
  environment        = "prod"
  eks_cluster_name   = "OptimusFrame-eks"

  create_argocd_record = true
  argocd_subdomain     = "argo"

  proxied = true
  ttl     = 300

  tags = {
    Project = "OptimusFrame"
  }
}
```

## Features

- Automatic EKS Load Balancer discovery
- Cloudflare proxy with CDN caching
- DDoS protection and WAF integration
- SSL/TLS termination at edge
- Geographic load balancing
- Real-time DNS updates

## Cloudflare Integration

### Proxy Benefits

- Global CDN with edge caching
- DDoS attack mitigation
- Web Application Firewall (WAF)
- SSL/TLS encryption
- Bot management
- Analytics and insights

### Security Features

- HTTPS enforcement
- HSTS headers
- Security headers injection
- Rate limiting
- IP filtering and blocking

## Load Balancer Discovery

The module automatically discovers the EKS Load Balancer address using:

```hcl
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}
```

## DNS Propagation

- TTL configuration for cache control
- Cloudflare global anycast network
- Sub-second DNS response times
- Automatic failover and redundancy

## Monitoring

- DNS query analytics
- Response time monitoring
- Error rate tracking
- Cache hit ratio metrics
- Geographic traffic distribution

## Best Practices

- Use low TTL values for dynamic records
- Enable Cloudflare proxy for performance
- Configure appropriate cache rules
- Monitor DNS propagation status
- Implement health checks for targets
