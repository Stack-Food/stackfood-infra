# API Gateway Module

## Overview

This module creates an AWS API Gateway with custom domain, Cognito authorization, and routing to both Lambda functions and EKS services via VPC Link.

## Resources Created

- REST API Gateway with custom domain
- Cognito User Pool Authorizer
- VPC Link for private EKS integration
- API Gateway deployment and stage
- CloudWatch logs for monitoring
- Request/response transformations

## Architecture

```
API Gateway (stackfood.com.br/api)
├── Custom Domain + SSL Certificate
├── Cognito Authorizer
├── Routes
│   ├── /auth/* → Lambda Functions
│   ├── /customer → Lambda Functions
│   └── /* → EKS via VPC Link
├── VPC Link → Network Load Balancer → EKS
└── CloudWatch Logs
```

## Inputs

| Variable                     | Type         | Description                  | Default  |
| ---------------------------- | ------------ | ---------------------------- | -------- |
| `api_name`                   | string       | API Gateway name             | required |
| `domain_name`                | string       | Custom domain name           | required |
| `certificate_arn`            | string       | ACM certificate ARN          | required |
| `cognito_user_pool_arn`      | string       | Cognito User Pool ARN        | required |
| `vpc_link_target_arns`       | list(string) | NLB ARNs for VPC Link        | required |
| `lambda_auth_invoke_arn`     | string       | Lambda auth function ARN     | required |
| `lambda_customer_invoke_arn` | string       | Lambda customer function ARN | required |
| `environment`                | string       | Environment name             | required |
| `tags`                       | map(string)  | Resource tags                | {}       |

## Route Configuration

| Method | Path             | Integration | Description                |
| ------ | ---------------- | ----------- | -------------------------- |
| ANY    | `/auth/{proxy+}` | Lambda      | Authentication endpoints   |
| POST   | `/customer`      | Lambda      | Customer creation          |
| GET    | `/swagger`       | VPC Link    | API documentation          |
| ANY    | `/{proxy+}`      | VPC Link    | All other endpoints to EKS |

## Outputs

| Output               | Description                 |
| -------------------- | --------------------------- |
| `api_gateway_id`     | API Gateway ID              |
| `api_gateway_arn`    | API Gateway ARN             |
| `api_gateway_url`    | API Gateway invoke URL      |
| `custom_domain_name` | Custom domain configuration |
| `vpc_link_id`        | VPC Link ID                 |

## Example Usage

```hcl
module "api_gateway" {
  source = "../modules/api-gateway/"

  api_name                     = "stackfood-api"
  domain_name                  = "stackfood.com.br"
  certificate_arn              = module.acm.certificate_arn
  cognito_user_pool_arn        = module.cognito.app_user_pool_arn
  vpc_link_target_arns         = [module.eks.load_balancer_arn]
  lambda_auth_invoke_arn       = module.lambda.auth_function_arn
  lambda_customer_invoke_arn   = module.lambda.customer_function_arn
  environment                  = "prod"

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- Custom domain with SSL termination
- Cognito User Pool authorization
- Request/response validation
- Rate limiting and throttling
- CORS configuration
- Request transformation
- CloudWatch logging and monitoring

## Integration Types

### Lambda Integration

- Direct proxy integration
- Automatic error handling
- Custom request/response mapping
- IAM role for Lambda invocation

### VPC Link Integration

- Private connectivity to EKS
- Network Load Balancer target
- Health check configuration
- Connection pooling

## Security

- WAF integration for protection
- API key authentication (optional)
- Request validation
- CORS policy enforcement
- CloudTrail logging
- VPC Link for private communication

## Monitoring

- CloudWatch metrics (latency, errors, count)
- X-Ray tracing integration
- Access logs to CloudWatch
- Custom metrics and alarms
- API usage analytics

## Performance

- Edge-optimized endpoint
- Caching configuration
- Request compression
- Connection keep-alive
- Regional deployment for lower latency
