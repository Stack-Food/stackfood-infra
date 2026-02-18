# RDS Module

## Overview

This module creates Amazon RDS PostgreSQL instances with high availability, backup, and monitoring configurations for persistent data storage.

## Resources Created

- RDS PostgreSQL instances
- DB Subnet Groups across multiple AZs
- Security Groups for database access
- DB Parameter Groups for performance tuning
- Option Groups for additional features
- Enhanced monitoring and performance insights

## Architecture

```
RDS PostgreSQL
├── Primary Instance (db.t3.micro)
├── Multi-AZ Deployment (optional)
├── Automated Backups (7 days retention)
├── Subnet Group (private subnets)
├── Security Group (port 5432)
└── Parameter Group (PostgreSQL 16)
```

## Inputs

| Variable             | Type         | Description                 | Default  |
| -------------------- | ------------ | --------------------------- | -------- |
| `rds_instances`      | map(object)  | RDS instance configurations | required |
| `vpc_id`             | string       | VPC ID for security groups  | required |
| `private_subnet_ids` | list(string) | Private subnet IDs          | required |
| `environment`        | string       | Environment name            | required |
| `tags`               | map(string)  | Resource tags               | {}       |

## RDS Instance Configuration

```hcl
rds_instances = {
  "instance-name" = {
    allocated_storage            = 20
    storage_encrypted            = true
    db_instance_class           = "db.t3.micro"
    db_username                 = "username"
    db_password                 = "password"
    engine                      = "postgres"
    engine_version              = "16.3"
    major_engine_version        = "16"
    identifier                  = "unique-identifier"
    publicly_accessible         = false
    multi_az                    = false
    performance_insights_enabled = false
    port                        = 5432
    backup_retention_period     = 7
    backup_window              = "03:00-04:00"
    maintenance_window         = "sun:04:00-sun:05:00"
  }
}
```

## Outputs

| Output                 | Description                 |
| ---------------------- | --------------------------- |
| `rds_instances`        | Map of RDS instance details |
| `db_subnet_group_name` | DB subnet group name        |
| `security_group_id`    | RDS security group ID       |

## Example Usage

```hcl
module "rds" {
  source = "../modules/rds/"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = "prod"

  rds_instances = {
    "OptimusFrame-db" = {
      allocated_storage     = 20
      db_instance_class    = "db.t3.micro"
      db_username          = "OptimusFrame"
      db_password          = "secure-password"
      engine               = "postgres"
      engine_version       = "16.3"
      identifier           = "OptimusFrame-postgres"
      publicly_accessible  = false
      multi_az            = false
    }
  }

  tags = {
    Project = "OptimusFrame"
  }
}
```

## Features

- PostgreSQL 16.3 with optimized configuration
- Automated backups with point-in-time recovery
- Security groups with restricted access
- Parameter groups for performance optimization
- Subnet groups for multi-AZ deployment
- Connection pooling support
- SSL/TLS encryption in transit

## Security

- Database in private subnets only
- Security groups allowing access from EKS only
- Encryption at rest with AWS KMS
- SSL connections enforced
- IAM database authentication support

## Backup & Recovery

- Automated daily backups
- 7-day backup retention
- Point-in-time recovery
- Manual snapshots before major changes
- Cross-region backup replication (optional)

## Monitoring

- Enhanced monitoring with 60-second granularity
- Performance Insights for query analysis
- CloudWatch metrics and alarms
- Slow query log analysis
- Connection monitoring
