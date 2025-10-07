# Cognito Module

## Overview

This module creates AWS Cognito User Pools for authentication, supporting both application users and ArgoCD administrators with OIDC integration.

## Resources Created

- Application User Pool for main application authentication
- ArgoCD User Pool for GitOps tool authentication
- User Pool Clients with OIDC configuration
- User Pool Domains for custom authentication URLs
- User Groups for role-based access control
- Pre-configured admin and team users

## Architecture

```
AWS Cognito
├── Application User Pool (stackfood-app)
│   ├── Guest User
│   ├── API Gateway Integration
│   └── Custom Authentication
├── ArgoCD User Pool (stackfood-argocd)
│   ├── Admin User (stackfood)
│   ├── Team Users (leonardo.duarte, luiz.felipe, etc.)
│   ├── OIDC Client
│   └── Admin/Readonly Groups
└── User Pool Domains
    ├── stackfood-app.auth.region.amazoncognito.com
    └── stackfood-argocd.auth.region.amazoncognito.com
```

## Inputs

| Variable                   | Type         | Description                  | Default          |
| -------------------------- | ------------ | ---------------------------- | ---------------- |
| `user_pool_name`           | string       | Base name for user pools     | required         |
| `environment`              | string       | Environment name             | required         |
| `create_app_user_pool`     | bool         | Create application user pool | true             |
| `guest_user_password`      | string       | Password for guest user      | required         |
| `stackfood_admin_password` | string       | Password for stackfood admin | "Fiap@2025"      |
| `argocd_team_users`        | map(object)  | Team users configuration     | {}               |
| `argocd_team_password`     | string       | Password for team users      | "StackFood@2025" |
| `argocd_callback_urls`     | list(string) | OIDC callback URLs           | []               |
| `argocd_logout_urls`       | list(string) | OIDC logout URLs             | []               |

## Team Users Configuration

```hcl
argocd_team_users = {
  "leonardo.duarte" = {
    name  = "Leonardo Duarte"
    email = "leo.duarte.dev@gmail.com"
  }
  "luiz.felipe" = {
    name  = "Luiz Felipe Maia"
    email = "luiz.felipeam@hotmail.com"
  }
  # ... additional users
}
```

## Outputs

| Output                          | Description                      |
| ------------------------------- | -------------------------------- |
| `app_user_pool_id`              | Application user pool ID         |
| `app_user_pool_client_id`       | Application client ID            |
| `argocd_user_pool_id`           | ArgoCD user pool ID              |
| `argocd_client_id`              | ArgoCD client ID                 |
| `argocd_client_secret`          | ArgoCD client secret (sensitive) |
| `argocd_issuer_url`             | OIDC issuer URL                  |
| `api_gateway_authorizer_config` | API Gateway configuration        |
| `argocd_team_users_created`     | Team users information           |

## Example Usage

```hcl
module "cognito" {
  source = "../modules/cognito/"

  user_pool_name = "stackfood"
  environment    = "prod"

  # Application user pool
  create_app_user_pool = true
  guest_user_password  = "SecurePassword123!"

  # ArgoCD configuration
  stackfood_admin_password = "Fiap@2025"
  argocd_team_password     = "StackFood@2025"

  argocd_team_users = {
    "leonardo.duarte" = {
      name  = "Leonardo Duarte"
      email = "leo.duarte.dev@gmail.com"
    }
  }

  argocd_callback_urls = [
    "https://argo.stackfood.com.br/api/dex/callback"
  ]

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- Dual user pool architecture for separation of concerns
- OIDC integration for ArgoCD GitOps authentication
- Automatic team user creation with email notifications
- Custom password policies and MFA support
- User groups for role-based access control
- Custom domains for branded authentication

## Authentication Flows

### Application User Pool

- Username/password authentication
- Guest user for public access
- API Gateway authorizer integration
- Custom authentication challenges

### ArgoCD User Pool

- OIDC authentication flow
- Group-based authorization
- Admin and readonly roles
- Team user management

## Security

- Strong password policies
- Email verification required
- Temporary passwords for new users
- MFA support (configurable)
- JWT token encryption
- Session management

## User Management

- Automatic user creation via Terraform
- Email invitations with temporary passwords
- Group membership assignment
- User attribute management
- Password reset workflows
