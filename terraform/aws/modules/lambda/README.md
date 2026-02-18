# Lambda Module

## Overview

This module creates AWS Lambda functions for serverless authentication and customer management, providing cost-effective and scalable serverless computing.

## Resources Created

- Lambda functions with configurable runtime
- IAM roles and policies for function execution
- CloudWatch log groups for monitoring
- Environment variables configuration
- Lambda layers for shared dependencies
- Dead letter queues for error handling

## Architecture

```
Lambda Functions
├── Auth Function
│   ├── Runtime: .NET 8 / Python 3.11
│   ├── Memory: 512 MB
│   ├── Timeout: 30 seconds
│   └── Environment Variables
├── Customer Function
│   ├── Runtime: .NET 8 / Python 3.11
│   ├── Memory: 256 MB
│   ├── Timeout: 15 seconds
│   └── Database Connection
├── IAM Roles
│   ├── Execution Role
│   ├── VPC Access (optional)
│   └── Service Permissions
└── CloudWatch Logs
    ├── Log Groups
    └── Log Retention (14 days)
```

## Inputs

| Variable           | Type        | Description                     | Default  |
| ------------------ | ----------- | ------------------------------- | -------- |
| `lambda_functions` | map(object) | Lambda function configurations  | required |
| `environment`      | string      | Environment name                | required |
| `vpc_config`       | object      | VPC configuration for functions | null     |
| `tags`             | map(string) | Resource tags                   | {}       |

## Lambda Function Configuration

```hcl
lambda_functions = {
  "auth" = {
    function_name = "OptimusFrame-auth"
    runtime      = "dotnet8"
    handler      = "OptimusFrame.Auth::OptimusFrame.Auth.Function::FunctionHandler"
    memory_size  = 512
    timeout      = 30
    filename     = "auth-function.zip"
    environment_variables = {
      COGNITO_USER_POOL_ID = "us-east-1_abc123"
    }
  }
  "customer" = {
    function_name = "OptimusFrame-customer"
    runtime      = "dotnet8"
    handler      = "OptimusFrame.Customer::OptimusFrame.Customer.Function::FunctionHandler"
    memory_size  = 256
    timeout      = 15
    filename     = "customer-function.zip"
    environment_variables = {
      DATABASE_URL = "postgresql://..."
    }
  }
}
```

## Outputs

| Output             | Description                        |
| ------------------ | ---------------------------------- |
| `lambda_functions` | Map of Lambda function details     |
| `function_arns`    | Map of function ARNs               |
| `invoke_arns`      | Map of invoke ARNs for API Gateway |
| `log_groups`       | CloudWatch log group names         |

## Example Usage

```hcl
module "lambda" {
  source = "../modules/lambda/"

  environment = "prod"

  lambda_functions = {
    "auth" = {
      function_name = "OptimusFrame-auth-prod"
      runtime      = "dotnet8"
      handler      = "OptimusFrame.Auth::OptimusFrame.Auth.Function::FunctionHandler"
      memory_size  = 512
      timeout      = 30
      filename     = "auth-function.zip"
      environment_variables = {
        COGNITO_USER_POOL_ID = module.cognito.app_user_pool_id
        ENVIRONMENT          = "prod"
      }
    }
  }

  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Project = "OptimusFrame"
  }
}
```

## Features

- Multiple runtime support (.NET, Python, Node.js)
- Automatic IAM role creation with least privilege
- CloudWatch logs with configurable retention
- Environment variable management
- VPC configuration for private resources access
- Dead letter queue for error handling
- Lambda layers for shared code/libraries

## Performance Optimization

- Configurable memory allocation
- Timeout settings per function
- Provisioned concurrency (optional)
- Connection pooling for databases
- Environment variable caching
- Cold start optimization

## Security

- IAM roles with minimal required permissions
- VPC deployment for private resource access
- Encryption at rest and in transit
- Environment variable encryption
- AWS X-Ray tracing integration
- CloudTrail logging

## Monitoring

- CloudWatch metrics (duration, errors, invocations)
- Custom metrics and alarms
- X-Ray distributed tracing
- Log aggregation and analysis
- Error tracking and alerting
- Performance insights

## Cost Optimization

- Pay-per-use pricing model
- Right-sized memory allocation
- Efficient timeout configuration
- Reserved concurrency management
- Dead letter queue for failed invocations
