# ArgoCD Module

## Overview

This module deploys ArgoCD on Kubernetes with Cognito OIDC authentication, providing a GitOps continuous delivery platform for automated application deployment and management.

## Resources Created

- ArgoCD Helm chart deployment
- OIDC integration with AWS Cognito
- RBAC configuration for user groups
- Ingress configuration with SSL
- Custom domain setup
- Service monitors and health checks

## Architecture

```
ArgoCD GitOps Platform
├── ArgoCD Server
│   ├── Web UI (argo.stackfood.com.br)
│   ├── gRPC API
│   └── OIDC Authentication
├── Application Controller
│   ├── Git Repository Sync
│   ├── Kubernetes Resource Management
│   └── Health Monitoring
├── Repository Server
│   ├── Git Cloning
│   ├── Manifest Rendering
│   └── Helm Chart Processing
├── Dex Server (OIDC)
│   ├── Cognito Integration
│   ├── User Authentication
│   └── Group Mapping
└── Redis Cache
    ├── Session Storage
    └── Application State Cache
```

## Inputs

| Variable                | Type        | Description               | Default           |
| ----------------------- | ----------- | ------------------------- | ----------------- |
| `domain_name`           | string      | Base domain name          | required          |
| `argocd_subdomain`      | string      | ArgoCD subdomain          | "argo"            |
| `cognito_user_pool_id`  | string      | Cognito User Pool ID      | required          |
| `cognito_client_id`     | string      | Cognito Client ID         | required          |
| `cognito_client_secret` | string      | Cognito Client Secret     | required          |
| `cognito_region`        | string      | AWS region for Cognito    | required          |
| `admin_group_name`      | string      | Admin group name          | "argocd-admin"    |
| `readonly_group_name`   | string      | Readonly group name       | "argocd-readonly" |
| `chart_version`         | string      | ArgoCD Helm chart version | "4.0.0"           |
| `certificate_arn`       | string      | ACM certificate ARN       | required          |
| `environment`           | string      | Environment name          | required          |
| `tags`                  | map(string) | Resource tags             | {}                |

## OIDC Configuration

```yaml
oidc.config: |
  name: Cognito
  issuer: https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx
  clientId: cognito-client-id
  clientSecret: cognito-client-secret
  redirectUri: https://argo.stackfood.com.br/api/dex/callback
  requestedScopes: ["email", "openid", "phone"]
  requestedIDTokenClaims: {"groups": {"essential": true}}
```

## RBAC Configuration

```yaml
policy.csv: |
  g, argocd-admin, role:admin
  g, argocd-readonly, role:readonly
```

## Outputs

| Output                   | Description                   |
| ------------------------ | ----------------------------- |
| `argocd_url`             | ArgoCD web interface URL      |
| `argocd_namespace`       | Kubernetes namespace          |
| `admin_password_command` | Command to get admin password |
| `oidc_configuration`     | OIDC configuration details    |

## Example Usage

```hcl
module "argocd" {
  source = "../modules/kubernetes/argocd/"

  domain_name      = "stackfood.com.br"
  argocd_subdomain = "argo"
  environment      = "prod"

  # Cognito OIDC configuration
  cognito_user_pool_id  = module.cognito.argocd_user_pool_id
  cognito_client_id     = module.cognito.argocd_client_id
  cognito_client_secret = module.cognito.argocd_client_secret
  cognito_region        = "us-east-1"

  # RBAC groups
  admin_group_name    = "argocd-admin"
  readonly_group_name = "argocd-readonly"

  # SSL certificate
  certificate_arn = module.acm.certificate_arn

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- GitOps workflow automation
- Multi-cluster application management
- Declarative configuration sync
- Health monitoring and alerting
- Application rollback capabilities
- Resource visualization and metrics

## Authentication Flow

1. User accesses https://argo.stackfood.com.br
2. ArgoCD redirects to Cognito OIDC provider
3. User authenticates with Cognito credentials
4. Cognito returns ID token with group claims
5. ArgoCD maps groups to RBAC roles
6. User gains access based on role permissions

## User Management

### Admin Users

- Full access to all applications and settings
- Can create, update, and delete applications
- Access to cluster and repository management
- System configuration capabilities

### Readonly Users

- View-only access to applications
- Can view logs and metrics
- Cannot modify applications or settings
- Limited to specific projects (optional)

## Application Management

- Git repository synchronization
- Helm chart deployment
- Kustomize support
- Multi-environment promotions
- Automated sync policies
- Manual approval workflows

## Monitoring and Observability

- Application health dashboards
- Sync status monitoring
- Resource drift detection
- Performance metrics
- Audit logging
- Webhook notifications

## Security

- RBAC with fine-grained permissions
- OIDC authentication integration
- TLS encryption for all communications
- Secret management with sealed secrets
- Network policies for pod isolation
- Image vulnerability scanning integration
