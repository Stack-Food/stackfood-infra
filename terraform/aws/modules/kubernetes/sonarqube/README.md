# SonarQube Terraform Module

This Terraform module deploys SonarQube Community Edition to an EKS cluster using the official SonarQube Helm chart with Cognito OIDC integration for authentication.

## Features

- 🎯 **Official SonarQube Helm Chart**: Uses the official SonarSource Helm chart
- 🔐 **Cognito OIDC Integration**: Seamless integration with AWS Cognito for authentication
- 🗃️ **PostgreSQL Database**: Embedded PostgreSQL or external database support
- 📊 **Monitoring Ready**: Prometheus metrics and ServiceMonitor included
- 🔒 **Security Hardened**: Pod Security Standards compliant
- 🌐 **Ingress Configured**: ALB/NLB ingress with SSL termination
- 💾 **Persistent Storage**: Configurable storage for SonarQube data

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   AWS Cognito   │────│   SonarQube  │────│ PostgreSQL  │
│  (OIDC Provider)│    │   (StatefulSet)   │ (Database)  │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │
                       ┌──────────────┐
                       │   Ingress    │
                       │ (ALB/NLB)    │
                       └──────────────┘
                              │
                       ┌──────────────┐
                       │   Route53    │
                       │   (DNS)      │
                       └──────────────┘
```

## Usage

### Basic Configuration

```hcl
module "sonarqube" {
  source = "./modules/kubernetes/sonarqube"

  # Domain configuration
  domain_name         = var.domain_name
  sonarqube_subdomain = "sonar"
  certificate_arn     = var.certificate_arn

  # Cognito OIDC configuration
  cognito_user_pool_id      = var.cognito_user_pool_id
  cognito_client_id         = var.cognito_client_id
  cognito_client_secret     = var.cognito_client_secret
  cognito_region            = var.aws_region
  cognito_client_issuer_url = var.cognito_client_issuer_url
  user_pool_name           = var.user_pool_name

  # Group mappings
  admin_group_name = "admins"
  user_group_name  = "users"

  # Storage configuration
  storage_size  = "20Gi"
  storage_class = "gp3"

  # Resource configuration
  sonarqube_resources = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2"
      memory = "8Gi"
    }
  }
}
```

### Advanced Configuration with External Database

```hcl
module "sonarqube" {
  source = "./modules/kubernetes/sonarqube"

  # ... basic configuration ...

  # Disable embedded PostgreSQL
  postgresql_enabled = false

  # External database configuration
  external_database = {
    enabled  = true
    host     = "sonarqube-db.cluster.amazonaws.com"
    port     = 5432
    name     = "sonarqube"
    username = "sonaruser"
    password = var.db_password  # Store securely
  }
}
```

## OIDC Configuration

The module automatically configures SonarQube to use AWS Cognito as an OIDC provider with the following settings:

- **Groups Sync**: Maps Cognito groups to SonarQube groups
- **Auto-provisioning**: Users are created automatically on first login
- **Role Mapping**:
  - Users in `admin_group_name` get SonarQube Administrator permissions
  - Users in `user_group_name` get SonarQube User permissions

### Required Cognito Configuration

Ensure your Cognito app client has:

1. **Allowed callback URLs**: `https://<sonar-subdomain>.<domain>/oauth2/callback/oidc`
2. **Allowed sign out URLs**: `https://<sonar-subdomain>.<domain>`
3. **Allowed OAuth flows**: Authorization code grant
4. **Allowed OAuth scopes**: `openid`, `email`, `profile`

## Input Variables

| Name                      | Description                                     | Type     | Default                       | Required |
| ------------------------- | ----------------------------------------------- | -------- | ----------------------------- | :------: |
| namespace                 | Kubernetes namespace for SonarQube              | `string` | `"sonarqube"`                 |    no    |
| chart_version             | SonarQube Helm chart version                    | `string` | `"10.7.0+3598"`               |    no    |
| domain_name               | Domain name for SonarQube                       | `string` | n/a                           |   yes    |
| sonarqube_subdomain       | Subdomain for SonarQube                         | `string` | `"sonar"`                     |    no    |
| cognito_user_pool_id      | Cognito User Pool ID for OIDC                   | `string` | n/a                           |   yes    |
| cognito_client_id         | Cognito App Client ID                           | `string` | n/a                           |   yes    |
| cognito_client_secret     | Cognito App Client Secret                       | `string` | n/a                           |   yes    |
| cognito_region            | AWS region where Cognito is deployed            | `string` | n/a                           |   yes    |
| cognito_client_issuer_url | Cognito OIDC issuer URL                         | `string` | n/a                           |   yes    |
| certificate_arn           | ACM certificate ARN for HTTPS                   | `string` | n/a                           |   yes    |
| admin_group_name          | Cognito group name for SonarQube administrators | `string` | `"admins"`                    |    no    |
| user_group_name           | Cognito group name for SonarQube users          | `string` | `"users"`                     |    no    |
| user_pool_name            | Cognito User Pool name                          | `string` | n/a                           |   yes    |
| storage_size              | Storage size for SonarQube data persistence     | `string` | `"10Gi"`                      |    no    |
| storage_class             | Storage class for SonarQube persistence         | `string` | `"gp2"`                       |    no    |
| sonarqube_resources       | Resource requests and limits for SonarQube      | `object` | See variables.tf              |    no    |
| postgresql_enabled        | Enable embedded PostgreSQL database             | `bool`   | `true`                        |    no    |
| postgresql_storage_size   | Storage size for PostgreSQL data                | `string` | `"20Gi"`                      |    no    |
| postgresql_resources      | Resource configuration for PostgreSQL           | `object` | See variables.tf              |    no    |
| external_database         | External database configuration                 | `object` | See variables.tf              |    no    |
| monitoring_passcode       | Monitoring passcode for SonarQube health checks | `string` | `"sonarqube-monitoring-pass"` |    no    |

## Output Values

| Name                | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| namespace           | Kubernetes namespace where SonarQube is deployed              |
| service_name        | SonarQube service name                                        |
| service_port        | SonarQube service port                                        |
| domain_name         | Full domain name for SonarQube                                |
| url                 | SonarQube URL                                                 |
| helm_release_name   | Helm release name for SonarQube                               |
| helm_release_status | Helm release status for SonarQube                             |
| postgresql_enabled  | Whether PostgreSQL is enabled as part of SonarQube deployment |

## Post-Deployment Configuration

After deployment, complete these steps:

### 1. Initial Admin Setup

1. Access SonarQube at `https://<sonar-subdomain>.<domain>`
2. Login with default credentials: `admin/admin`
3. Change the admin password immediately
4. Configure OIDC authentication in Administration > Configuration > General > Authentication

### 2. Group Permissions

Configure group permissions in Administration > Security > Global Permissions:

- Map your Cognito admin group to "Administer System" permission
- Map your Cognito user group to appropriate project permissions

### 3. Quality Profiles and Rules

1. Configure quality profiles for your programming languages
2. Set up quality gates based on your requirements
3. Configure webhooks for CI/CD integration

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: SonarQube Scan
  uses: sonarqube-quality-gate-action@master
  with:
    scanMetadataReportFile: target/sonar/report-task.txt
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: https://sonar.yourdomain.com
```

### Jenkins Pipeline Example

```groovy
stage('SonarQube Analysis') {
  steps {
    withSonarQubeEnv('SonarQube') {
      sh 'mvn clean package sonar:sonar'
    }
  }
}
```

## Monitoring

The module includes:

- **ServiceMonitor**: For Prometheus metrics scraping
- **Health Checks**: Readiness, liveness, and startup probes
- **Metrics Endpoint**: `/api/monitoring/metrics`

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check resource limits and storage class availability
2. **OIDC login fails**: Verify Cognito callback URLs and client configuration
3. **Database connection issues**: Check PostgreSQL pod status and credentials

### Useful Commands

```bash
# Check pod status
kubectl get pods -n sonarqube

# View pod logs
kubectl logs -f deployment/sonarqube -n sonarqube

# Check OIDC configuration
kubectl get secret sonarqube-oidc-config -n sonarqube -o yaml

# Test database connectivity
kubectl exec -it sonarqube-postgresql-0 -n sonarqube -- psql -U sonarUser -d sonarDB
```

## Security Considerations

- 🔐 OIDC secrets are stored in Kubernetes secrets
- 🛡️ Pod Security Standards compliant containers
- 🚫 Non-root container execution
- 📝 Database credentials should be rotated regularly
- 🌐 Use HTTPS only for production deployments

## Version Compatibility

- **SonarQube**: 10.x (Community Edition)
- **PostgreSQL**: 11.x
- **Kubernetes**: 1.24+
- **Helm**: 3.x

## License

This module is released under the MIT License. SonarQube Community Edition is available under the LGPL v3 license.
