# SonarQube Terraform Module

This Terraform module provides a complete SonarQube Community Edition deployment for EKS clusters with AWS Cognito OIDC integration, PostgreSQL database, and comprehensive monitoring capabilities.

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Configuration](#configuration)
6. [Variables Reference](#variables-reference)
7. [Outputs Reference](#outputs-reference)
8. [Post-Deployment Setup](#post-deployment-setup)
9. [CI/CD Integration](#cicd-integration)
10. [Monitoring & Observability](#monitoring--observability)
11. [Security Best Practices](#security-best-practices)
12. [Troubleshooting](#troubleshooting)
13. [Performance Tuning](#performance-tuning)
14. [Backup & Recovery](#backup--recovery)
15. [Migration Guide](#migration-guide)

## Features

- 🎯 **Official SonarQube Helm Chart**: Uses the official SonarSource Helm chart (v10.7.0+3598)
- 🔐 **Cognito OIDC Integration**: Seamless SSO integration with AWS Cognito
- 🗃️ **PostgreSQL Database**: Embedded PostgreSQL or external database support
- 📊 **Monitoring Ready**: Prometheus metrics and ServiceMonitor included
- 🔒 **Security Hardened**: Pod Security Standards compliant
- 🌐 **Ingress Configured**: ALB/NLB ingress with SSL termination
- 💾 **Persistent Storage**: Configurable storage with different storage classes
- 🚀 **CI/CD Ready**: Pre-configured for integration with popular CI/CD platforms
- 📈 **Scalable**: Resource configuration for teams of all sizes
- 🔄 **High Availability**: Support for external databases and load balancing

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   AWS Cognito   │────│   SonarQube  │────│ PostgreSQL  │
│  (OIDC Provider)│    │ (StatefulSet) │    │ (Database)  │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │                     │
                       ┌──────────────┐    ┌─────────────┐
                       │   Ingress    │    │  Storage    │
                       │ (ALB/NLB)    │    │ (PVC/PV)    │
                       └──────────────┘    └─────────────┘
                              │
                       ┌──────────────┐
                       │   Route53    │
                       │   (DNS)      │
                       └──────────────┘
```

### Components

- **SonarQube Application**: Main application deployed as a StatefulSet
- **PostgreSQL Database**: Either embedded or external database for persistence
- **NGINX Ingress**: Load balancer and SSL termination
- **Persistent Volumes**: Storage for SonarQube data and PostgreSQL
- **ServiceMonitor**: Prometheus metrics collection
- **Secrets**: OIDC configuration and database credentials

## Prerequisites

Before deploying this module, ensure you have:

1. **EKS Cluster**: Kubernetes 1.24+ with RBAC enabled
2. **NGINX Ingress Controller**: Installed and configured in the cluster
3. **AWS Cognito User Pool**:
   - Configured with appropriate user groups
   - OIDC client with proper callback URLs
   - Users assigned to relevant groups
4. **ACM Certificate**: Valid SSL certificate for your domain
5. **DNS Management**: Cloudflare or Route53 for domain configuration
6. **Storage Classes**: Available storage classes (gp2, gp3, etc.)
7. **Terraform**: Version 1.0+ with Kubernetes and Helm providers

### Required AWS Permissions

The deployment requires the following AWS permissions:

- Cognito: Read access to user pools and app clients
- ACM: Read access to certificates
- Route53/Cloudflare: DNS record management

## Quick Start

### 1. Basic Configuration

```hcl
module "sonarqube" {
  source = "./modules/kubernetes/sonarqube"

  # Domain configuration
  domain_name         = "your-domain.com"
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
  admin_group_name = "system-admins"
  user_group_name  = "sonarqube"

  # Storage configuration
  storage_size  = "50Gi"
  storage_class = "gp3"

  # Resource configuration
  sonarqube_resources = {
    requests = {
      cpu    = "1"
      memory = "4Gi"
    }
    limits = {
      cpu    = "4"
      memory = "16Gi"
    }
  }
}
```

### 2. Deploy

```bash
# Navigate to your Terraform directory
cd terraform/aws/main/

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 3. Verify Deployment

```bash
# Check pod status
kubectl get pods -n sonarqube

# Check services and ingress
kubectl get svc,ingress -n sonarqube

# Verify DNS resolution
nslookup sonar.your-domain.com
```

## Configuration

### Production Configuration

```hcl
module "sonarqube" {
  source = "./modules/kubernetes/sonarqube"

  # Basic configuration
  namespace           = "sonarqube"
  domain_name         = "company.com"
  sonarqube_subdomain = "sonar"
  environment         = "prod"

  # Cognito integration
  cognito_user_pool_id      = module.cognito.user_pool_id
  cognito_client_id         = module.cognito.sonarqube_client_id
  cognito_client_secret     = module.cognito.sonarqube_client_secret
  cognito_region            = "us-east-1"
  cognito_client_issuer_url = module.cognito.sonarqube_issuer_url
  user_pool_name            = module.cognito.user_pool_name

  # Group mappings
  admin_group_name = "system-admins"
  user_group_name  = "sonarqube"

  # SSL certificate
  certificate_arn = module.acm.certificate_arn

  # Production storage
  storage_size  = "100Gi"
  storage_class = "gp3"

  # Production resources
  sonarqube_resources = {
    requests = {
      cpu    = "2"
      memory = "8Gi"
    }
    limits = {
      cpu    = "8"
      memory = "32Gi"
    }
  }

  # PostgreSQL configuration
  postgresql_enabled      = true
  postgresql_storage_size = "500Gi"
  postgresql_resources = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "4"
      memory = "8Gi"
    }
  }

  depends_on = [
    module.eks,
    module.nginx-ingress,
    module.cognito
  ]
}
```

### External Database Configuration

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
    password = var.db_password  # Store in AWS Secrets Manager
  }
}
```

### Multi-Environment Configuration

```hcl
# Development
module "sonarqube_dev" {
  source = "./modules/kubernetes/sonarqube"

  namespace           = "sonarqube-dev"
  sonarqube_subdomain = "sonar-dev"
  storage_size        = "20Gi"

  sonarqube_resources = {
    requests = { cpu = "500m", memory = "2Gi" }
    limits   = { cpu = "2", memory = "8Gi" }
  }
}

# Staging
module "sonarqube_staging" {
  source = "./modules/kubernetes/sonarqube"

  namespace           = "sonarqube-staging"
  sonarqube_subdomain = "sonar-staging"
  storage_size        = "50Gi"

  sonarqube_resources = {
    requests = { cpu = "1", memory = "4Gi" }
    limits   = { cpu = "4", memory = "16Gi" }
  }
}

# Production (see above example)
```

## Variables Reference

### Required Variables

| Name                        | Type     | Description                                     |
| --------------------------- | -------- | ----------------------------------------------- |
| `domain_name`               | `string` | Domain name for SonarQube (e.g., "company.com") |
| `cognito_user_pool_id`      | `string` | Cognito User Pool ID for OIDC authentication    |
| `cognito_client_id`         | `string` | Cognito App Client ID                           |
| `cognito_client_secret`     | `string` | Cognito App Client Secret (sensitive)           |
| `cognito_region`            | `string` | AWS region where Cognito is deployed            |
| `cognito_client_issuer_url` | `string` | Cognito OIDC issuer URL                         |
| `certificate_arn`           | `string` | ACM certificate ARN for HTTPS                   |
| `user_pool_name`            | `string` | Cognito User Pool name                          |

### Optional Variables

| Name                      | Type     | Default                       | Description                      |
| ------------------------- | -------- | ----------------------------- | -------------------------------- |
| `namespace`               | `string` | `"sonarqube"`                 | Kubernetes namespace             |
| `chart_version`           | `string` | `"10.7.0+3598"`               | SonarQube Helm chart version     |
| `sonarqube_subdomain`     | `string` | `"sonar"`                     | Subdomain for SonarQube          |
| `environment`             | `string` | `"prod"`                      | Environment name                 |
| `admin_group_name`        | `string` | `"admins"`                    | Cognito group for administrators |
| `user_group_name`         | `string` | `"users"`                     | Cognito group for regular users  |
| `storage_size`            | `string` | `"10Gi"`                      | Storage size for SonarQube data  |
| `storage_class`           | `string` | `"gp2"`                       | Storage class for persistence    |
| `postgresql_enabled`      | `bool`   | `true`                        | Enable embedded PostgreSQL       |
| `postgresql_storage_size` | `string` | `"20Gi"`                      | PostgreSQL storage size          |
| `monitoring_passcode`     | `string` | `"sonarqube-monitoring-pass"` | Monitoring passcode              |

### Resource Configuration Objects

```hcl
# SonarQube resources
sonarqube_resources = {
  requests = {
    cpu    = "400m"      # Minimum CPU
    memory = "2048M"     # Minimum memory
  }
  limits = {
    cpu    = "800m"      # Maximum CPU
    memory = "6144M"     # Maximum memory
  }
}

# PostgreSQL resources
postgresql_resources = {
  requests = {
    cpu    = "100m"      # Minimum CPU
    memory = "200Mi"     # Minimum memory
  }
  limits = {
    cpu    = "2"         # Maximum CPU
    memory = "2Gi"       # Maximum memory
  }
}

# External database configuration
external_database = {
  enabled  = false       # Enable external database
  host     = ""          # Database host
  port     = 5432        # Database port
  name     = ""          # Database name
  username = ""          # Database username
  password = ""          # Database password
}
```

## Outputs Reference

| Name                  | Description                                      |
| --------------------- | ------------------------------------------------ |
| `namespace`           | Kubernetes namespace where SonarQube is deployed |
| `service_name`        | SonarQube service name                           |
| `service_port`        | SonarQube service port (9000)                    |
| `domain_name`         | Full domain name for SonarQube                   |
| `url`                 | Complete SonarQube URL                           |
| `helm_release_name`   | Helm release name                                |
| `helm_release_status` | Helm release status                              |
| `postgresql_enabled`  | Whether PostgreSQL is enabled                    |

### Using Outputs

```hcl
# Reference SonarQube URL in other modules
resource "aws_route53_record" "sonarqube" {
  zone_id = var.route53_zone_id
  name    = module.sonarqube.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}

# Use in CI/CD variables
output "sonarqube_url_for_ci" {
  value = module.sonarqube.url
}
```

## Post-Deployment Setup

### 1. Initial Access and Configuration

1. **Access SonarQube**:

   ```bash
   # Open in browser
   open https://sonar.your-domain.com
   ```

2. **First Login**:

   - Use default credentials: `admin/admin`
   - Change admin password immediately
   - Setup admin email and notifications

3. **Enable OIDC Authentication**:
   - Go to Administration > Configuration > General > Authentication
   - Enable "OpenID Connect"
   - Configure OIDC settings (auto-configured by Terraform)

### 2. User and Group Management

1. **Verify Group Mappings**:

   ```bash
   # Check OIDC configuration
   kubectl get secret sonarqube-oidc-config -n sonarqube -o yaml
   ```

2. **Configure Permissions**:

   - Administration > Security > Global Permissions
   - Assign permissions to Cognito groups:
     - `system-admins` → Administer System
     - `sonarqube` → Browse, Execute Analysis

3. **Test User Login**:
   - Logout from admin account
   - Login with Cognito user
   - Verify group membership and permissions

### 3. Quality Profile Configuration

1. **Language Profiles**:

   - Administration > Quality Profiles
   - Set up profiles for your languages (Java, JavaScript, Python, etc.)
   - Configure rules and quality gates

2. **Quality Gates**:
   - Administration > Quality Gates
   - Create custom quality gates
   - Set coverage, duplicates, and security thresholds

### 4. Project Setup

1. **Create Projects**:

   - Projects > Create Project
   - Manual or automatic project discovery

2. **Generate Tokens**:
   ```bash
   # Generate analysis token for CI/CD
   curl -u admin:admin -X POST \
     "https://sonar.your-domain.com/api/user_tokens/generate" \
     -d "name=ci-token" \
     -d "type=USER_TOKEN"
   ```

## CI/CD Integration

### GitHub Actions

```yaml
name: SonarQube Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  sonarqube:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 # Full history for blame info

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: "temurin"
          java-version: "11"

      - name: Cache SonarQube packages
        uses: actions/cache@v3
        with:
          path: ~/.sonar/cache
          key: ${{ runner.os }}-sonar
          restore-keys: ${{ runner.os }}-sonar

      - name: Run tests
        run: mvn clean test

      - name: SonarQube Analysis
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: https://sonar.your-domain.com
        run: |
          mvn sonar:sonar \
            -Dsonar.projectKey=my-project \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONAR_TOKEN

      - name: Quality Gate Check
        uses: sonarqube-quality-gate-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        timeout-minutes: 5
```

### GitLab CI/CD

```yaml
stages:
  - build
  - test
  - sonarqube
  - deploy

variables:
  SONAR_HOST: "https://sonar.your-domain.com"
  SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
  GIT_DEPTH: "0"

cache:
  paths:
    - .sonar/cache

build:
  stage: build
  script:
    - mvn clean compile

test:
  stage: test
  script:
    - mvn test
  artifacts:
    reports:
      junit: target/surefire-reports/TEST-*.xml
    paths:
      - target/

sonarqube-check:
  stage: sonarqube
  image: maven:3.8-openjdk-11
  script:
    - mvn sonar:sonar
      -Dsonar.projectKey=$CI_PROJECT_NAME
      -Dsonar.host.url=$SONAR_HOST
      -Dsonar.login=$SONAR_TOKEN
  only:
    - main
    - develop
    - merge_requests
```

### Project Configuration Examples

#### Node.js

```json
{
  "scripts": {
    "test": "jest --coverage",
    "sonar": "sonar-scanner"
  },
  "jest": {
    "coverageDirectory": "coverage",
    "coverageReporters": ["lcov", "text"]
  },
  "devDependencies": {
    "sonarqube-scanner": "^3.0.1",
    "jest": "^29.0.0"
  }
}
```

```javascript
// sonar-project.js
const sonarqubeScanner = require("sonarqube-scanner");

sonarqubeScanner(
  {
    serverUrl: "https://sonar.your-domain.com",
    options: {
      "sonar.projectKey": "my-node-project",
      "sonar.projectName": "My Node.js Project",
      "sonar.sources": "src",
      "sonar.tests": "tests",
      "sonar.javascript.lcov.reportPaths": "coverage/lcov.info",
      "sonar.testExecutionReportPaths": "coverage/test-reporter.xml",
    },
  },
  () => {
    console.log("SonarQube analysis completed");
  }
);
```

#### .NET Core

```xml
<!-- Directory.Build.props -->
<Project>
  <PropertyGroup>
    <SonarQubeProjectKey>my-dotnet-project</SonarQubeProjectKey>
    <SonarQubeHostUrl>https://sonar.your-domain.com</SonarQubeHostUrl>
  </PropertyGroup>
</Project>
```

```yaml
# Azure DevOps Pipeline
steps:
  - task: SonarQubePrepare@5
    inputs:
      SonarQube: "SonarQube"
      scannerMode: "MSBuild"
      projectKey: "my-dotnet-project"
      projectName: "My .NET Project"

  - task: DotNetCoreCLI@2
    inputs:
      command: "build"
      projects: "**/*.csproj"

  - task: DotNetCoreCLI@2
    inputs:
      command: "test"
      projects: "**/*Tests.csproj"
      arguments: '--collect:"XPlat Code Coverage"'

  - task: SonarQubeAnalyze@5

  - task: SonarQubePublish@5
```

## Monitoring & Observability

### Prometheus Metrics

SonarQube exposes comprehensive metrics at `/api/monitoring/metrics`:

```yaml
# ServiceMonitor (automatically created by module)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: sonarqube-metrics
  namespace: sonarqube
spec:
  selector:
    matchLabels:
      app: sonarqube
  endpoints:
    - port: http
      path: /api/monitoring/metrics
      interval: 30s
      scrapeTimeout: 10s
```

### Key Metrics

- **System Health**:

  - `sonarqube_health_status`: Overall system health
  - `sonarqube_database_pool_active_connections`: DB connections
  - `sonarqube_elasticsearch_status`: Search engine status

- **Analysis Performance**:

  - `sonarqube_compute_engine_pending_tasks`: Queued analyses
  - `sonarqube_compute_engine_processing_time`: Analysis duration
  - `sonarqube_lines_of_code_total`: Total lines analyzed

- **User Activity**:
  - `sonarqube_active_users_total`: Active user count
  - `sonarqube_projects_total`: Total projects
  - `sonarqube_issues_total`: Total issues by severity

### Grafana Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "SonarQube Monitoring",
    "panels": [
      {
        "title": "System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_health_status",
            "legendFormat": "Health Status"
          }
        ]
      },
      {
        "title": "Analysis Queue",
        "type": "graph",
        "targets": [
          {
            "expr": "sonarqube_compute_engine_pending_tasks",
            "legendFormat": "Pending Tasks"
          }
        ]
      }
    ]
  }
}
```

### Alerting Rules

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: sonarqube-alerts
  namespace: sonarqube
spec:
  groups:
    - name: sonarqube
      rules:
        - alert: SonarQubeDown
          expr: up{job="sonarqube"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "SonarQube is down"
            description: "SonarQube has been down for more than 5 minutes"

        - alert: SonarQubeHighQueueLength
          expr: sonarqube_compute_engine_pending_tasks > 100
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "SonarQube analysis queue is high"
            description: "Analysis queue has {{ $value }} pending tasks"

        - alert: SonarQubeDatabaseConnectionsHigh
          expr: sonarqube_database_pool_active_connections > 80
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "SonarQube database connections high"
            description: "Database has {{ $value }} active connections"
```

### Health Checks

```bash
# Manual health check scripts
#!/bin/bash

# Check SonarQube health
curl -s https://sonar.your-domain.com/api/system/health | jq '.health'

# Check database connectivity
kubectl exec -it sonarqube-postgresql-0 -n sonarqube -- \
  pg_isready -U sonarUser -d sonarDB

# Check analysis queue
curl -s https://sonar.your-domain.com/api/ce/activity | \
  jq '.tasks[] | select(.status=="PENDING") | .id'

# Check disk usage
kubectl exec -it deployment/sonarqube -n sonarqube -- \
  df -h /opt/sonarqube/data
```

## Security Best Practices

### Authentication and Authorization

1. **Disable Local Authentication**:

   ```bash
   # In SonarQube admin panel
   Administration > Configuration > General > Security
   # Set "Force user authentication" to true
   # Disable "Enable users to sign up"
   ```

2. **Regular Token Rotation**:

   ```bash
   # Rotate analysis tokens quarterly
   curl -u admin:password -X POST \
     "https://sonar.your-domain.com/api/user_tokens/revoke" \
     -d "name=old-token"

   curl -u admin:password -X POST \
     "https://sonar.your-domain.com/api/user_tokens/generate" \
     -d "name=new-token"
   ```

3. **Audit User Access**:
   ```bash
   # Regular access review
   curl -u admin:password \
     "https://sonar.your-domain.com/api/users/search" | \
     jq '.users[] | {login, name, active, groups}'
   ```

### Network Security

1. **HTTPS Only**:

   ```yaml
   # In sonarqube.yaml template
   sonar.forceAuthentication: true
   sonar.web.sso.enable: true
   sonar.security.realm: OIDC
   ```

2. **Network Policies**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: sonarqube-network-policy
     namespace: sonarqube
   spec:
     podSelector:
       matchLabels:
         app: sonarqube
     policyTypes:
       - Ingress
       - Egress
     ingress:
       - from:
           - namespaceSelector:
               matchLabels:
                 name: ingress-nginx
         ports:
           - protocol: TCP
             port: 9000
     egress:
       - to:
           - podSelector:
               matchLabels:
                 app: postgresql
         ports:
           - protocol: TCP
             port: 5432
       - to: []
         ports:
           - protocol: TCP
             port: 443 # HTTPS egress
           - protocol: TCP
             port: 53 # DNS
           - protocol: UDP
             port: 53 # DNS
   ```

### Data Protection

1. **Encrypt Secrets**:

   ```bash
   # Use sealed-secrets or external secrets operator
   kubectl create secret generic sonarqube-secrets \
     --from-literal=client-secret="your-secret" \
     --from-literal=db-password="your-password" \
     --dry-run=client -o yaml | \
     kubeseal -o yaml > sonarqube-sealed-secrets.yaml
   ```

2. **Database Security**:

   ```sql
   -- Regular password rotation
   ALTER USER sonaruser WITH PASSWORD 'new-complex-password';

   -- Review database permissions
   SELECT * FROM pg_roles WHERE rolname = 'sonaruser';
   ```

3. **Backup Encryption**:
   ```bash
   # Encrypted database backup
   kubectl exec sonarqube-postgresql-0 -n sonarqube -- \
     pg_dump -U sonarUser sonarDB | \
     gpg --cipher-algo AES256 --compress-algo 1 \
     --symmetric --output backup-$(date +%Y%m%d).sql.gpg
   ```

### Security Scanning

1. **Container Scanning**:

   ```yaml
   # Add to CI/CD pipeline
   - name: Container Security Scan
     uses: aquasecurity/trivy-action@master
     with:
       image-ref: "sonarqube:10.7-community"
       format: "sarif"
       output: "trivy-results.sarif"
   ```

2. **Configuration Auditing**:

   ```bash
   # Use kube-bench for cluster security
   kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

   # Use falco for runtime security
   helm repo add falcosecurity https://falcosecurity.github.io/charts
   helm install falco falcosecurity/falco --namespace falco --create-namespace
   ```

## Troubleshooting

### Common Issues

#### 1. Pod Not Starting

**Symptoms**:

- Pod in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff` state
- Application not accessible

**Diagnosis**:

```bash
# Check pod status
kubectl get pods -n sonarqube

# Describe pod for events
kubectl describe pod <pod-name> -n sonarqube

# Check pod logs
kubectl logs <pod-name> -n sonarqube --previous
```

**Common Causes & Solutions**:

1. **Resource Constraints**:

   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes

   # Adjust resource requests/limits
   # In your terraform configuration:
   sonarqube_resources = {
     requests = { cpu = "500m", memory = "2Gi" }
     limits   = { cpu = "2", memory = "8Gi" }
   }
   ```

2. **Storage Issues**:

   ```bash
   # Check PVC status
   kubectl get pvc -n sonarqube

   # Check storage class
   kubectl get storageclass

   # Verify PV availability
   kubectl get pv
   ```

3. **Image Pull Issues**:

   ```bash
   # Check image availability
   docker pull sonarqube:10.7-community

   # Check node connectivity to registry
   kubectl debug node/<node-name> -it --image=busybox
   ```

#### 2. Database Connection Issues

**Symptoms**:

- SonarQube logs show database connection errors
- Application fails to start completely

**Diagnosis**:

```bash
# Check PostgreSQL pod status
kubectl get pods -n sonarqube -l app=postgresql

# Check PostgreSQL logs
kubectl logs sonarqube-postgresql-0 -n sonarqube

# Test database connectivity
kubectl exec -it sonarqube-postgresql-0 -n sonarqube -- \
  psql -U sonarUser -d sonarDB -c "SELECT version();"
```

**Solutions**:

1. **PostgreSQL Not Running**:

   ```bash
   # Restart PostgreSQL
   kubectl delete pod sonarqube-postgresql-0 -n sonarqube

   # Check storage for PostgreSQL
   kubectl get pvc -n sonarqube -l app=postgresql
   ```

2. **Connection Configuration**:

   ```bash
   # Verify database credentials
   kubectl get secret sonarqube-postgresql -n sonarqube -o yaml

   # Check connection string
   kubectl exec -it deployment/sonarqube -n sonarqube -- \
     env | grep SONAR_JDBC
   ```

3. **External Database Issues**:
   ```bash
   # Test external database connectivity
   kubectl run -it --rm debug --image=postgres:11 --restart=Never -- \
     psql -h <external-host> -U <username> -d <database>
   ```

#### 3. OIDC Authentication Issues

**Symptoms**:

- Users cannot login via SSO
- OIDC redirect loops
- "Invalid client" errors

**Diagnosis**:

```bash
# Check OIDC configuration
kubectl get secret sonarqube-oidc-config -n sonarqube -o yaml

# Check SonarQube OIDC logs
kubectl logs deployment/sonarqube -n sonarqube | grep -i oidc

# Verify Cognito configuration
aws cognito-idp describe-user-pool-client \
  --user-pool-id <pool-id> \
  --client-id <client-id>
```

**Solutions**:

1. **Incorrect Callback URLs**:

   ```bash
   # Update Cognito client callback URLs
   aws cognito-idp update-user-pool-client \
     --user-pool-id <pool-id> \
     --client-id <client-id> \
     --callback-urls "https://sonar.your-domain.com/oauth2/callback/oidc"
   ```

2. **Client Secret Mismatch**:

   ```bash
   # Regenerate client secret
   aws cognito-idp update-user-pool-client \
     --user-pool-id <pool-id> \
     --client-id <client-id> \
     --generate-secret

   # Update Terraform configuration with new secret
   ```

3. **Group Mapping Issues**:

   ```bash
   # Check user group membership
   aws cognito-idp admin-list-groups-for-user \
     --user-pool-id <pool-id> \
     --username <username>

   # Verify group configuration in SonarQube
   # Administration > Security > Groups
   ```

#### 4. Performance Issues

**Symptoms**:

- Slow analysis times
- High memory usage
- Timeouts during analysis

**Diagnosis**:

```bash
# Check resource usage
kubectl top pods -n sonarqube

# Check analysis queue
curl -s https://sonar.your-domain.com/api/ce/activity | \
  jq '.tasks[] | select(.status=="PENDING")'

# Check system info
curl -s https://sonar.your-domain.com/api/system/info | jq
```

**Solutions**:

1. **Increase Resources**:

   ```hcl
   # For large teams/codebases
   sonarqube_resources = {
     requests = { cpu = "2", memory = "8Gi" }
     limits   = { cpu = "8", memory = "32Gi" }
   }
   ```

2. **Optimize JVM Settings**:

   ```yaml
   # In sonarqube.yaml template
   env:
     - name: SONAR_WEB_JAVAOPTS
       value: "-Xmx8G -XX:MaxDirectMemorySize=2G"
     - name: SONAR_CE_JAVAOPTS
       value: "-Xmx8G -XX:MaxDirectMemorySize=1G"
   ```

3. **Database Performance**:

   ```sql
   -- Check database performance
   SELECT query, calls, total_time, mean_time
   FROM pg_stat_statements
   ORDER BY total_time DESC LIMIT 10;

   -- Optimize database
   ANALYZE;
   REINDEX DATABASE sonarDB;
   ```

### Debugging Commands

```bash
# Essential debugging commands

# 1. Check overall status
kubectl get all -n sonarqube

# 2. Detailed pod information
kubectl describe pod -l app=sonarqube -n sonarqube

# 3. Application logs
kubectl logs -f deployment/sonarqube -n sonarqube

# 4. Database logs
kubectl logs -f sonarqube-postgresql-0 -n sonarqube

# 5. Check ingress
kubectl get ingress -n sonarqube -o yaml

# 6. Network connectivity test
kubectl exec -it deployment/sonarqube -n sonarqube -- \
  curl -I https://sonar.your-domain.com

# 7. DNS resolution test
kubectl exec -it deployment/sonarqube -n sonarqube -- \
  nslookup sonar.your-domain.com

# 8. Check secrets
kubectl get secrets -n sonarqube

# 9. Resource usage
kubectl top pods -n sonarqube --containers

# 10. Event monitoring
kubectl get events -n sonarqube --sort-by='.lastTimestamp'
```

### Log Analysis

```bash
# Analyze SonarQube logs for common issues

# Authentication issues
kubectl logs deployment/sonarqube -n sonarqube | \
  grep -i "authentication\|oidc\|oauth"

# Database connectivity
kubectl logs deployment/sonarqube -n sonarqube | \
  grep -i "database\|jdbc\|postgresql"

# Performance issues
kubectl logs deployment/sonarqube -n sonarqube | \
  grep -i "memory\|timeout\|slow"

# Analysis errors
kubectl logs deployment/sonarqube -n sonarqube | \
  grep -i "analysis\|scanner\|error"
```

## Performance Tuning

### Resource Sizing Guidelines

#### Small Teams (< 10 developers)

```hcl
sonarqube_resources = {
  requests = { cpu = "500m", memory = "2Gi" }
  limits   = { cpu = "2", memory = "8Gi" }
}

postgresql_resources = {
  requests = { cpu = "250m", memory = "512Mi" }
  limits   = { cpu = "1", memory = "2Gi" }
}

storage_size = "20Gi"
postgresql_storage_size = "50Gi"
```

#### Medium Teams (10-50 developers)

```hcl
sonarqube_resources = {
  requests = { cpu = "1", memory = "4Gi" }
  limits   = { cpu = "4", memory = "16Gi" }
}

postgresql_resources = {
  requests = { cpu = "500m", memory = "1Gi" }
  limits   = { cpu = "2", memory = "4Gi" }
}

storage_size = "50Gi"
postgresql_storage_size = "200Gi"
```

#### Large Teams (> 50 developers)

```hcl
sonarqube_resources = {
  requests = { cpu = "2", memory = "8Gi" }
  limits   = { cpu = "8", memory = "32Gi" }
}

postgresql_resources = {
  requests = { cpu = "1", memory = "2Gi" }
  limits   = { cpu = "4", memory = "8Gi" }
}

storage_size = "100Gi"
postgresql_storage_size = "500Gi"
storage_class = "gp3"  # Better performance
```

### JVM Optimization

```yaml
# Advanced JVM tuning for high-performance setups
env:
  - name: SONAR_WEB_JAVAOPTS
    value: |
      -Xmx8G 
      -XX:MaxDirectMemorySize=2G 
      -XX:+UseG1GC 
      -XX:+UseStringDeduplication
      -XX:MaxGCPauseMillis=200
      -XX:ParallelGCThreads=8

  - name: SONAR_CE_JAVAOPTS
    value: |
      -Xmx8G 
      -XX:MaxDirectMemorySize=1G
      -XX:+UseG1GC
      -XX:+UseStringDeduplication
      -XX:MaxGCPauseMillis=200
      -XX:ParallelGCThreads=4

  - name: SONAR_SEARCH_JAVAOPTS
    value: |
      -Xmx2G
      -XX:MaxDirectMemorySize=1G
      -XX:+UseG1GC
```

### Database Optimization

```sql
-- PostgreSQL performance tuning
-- Connect to database
kubectl exec -it sonarqube-postgresql-0 -n sonarqube -- \
  psql -U sonarUser -d sonarDB

-- Adjust configuration
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET default_statistics_target = 100;

-- Reload configuration
SELECT pg_reload_conf();

-- Create indexes for common queries
CREATE INDEX CONCURRENTLY idx_issues_component_uuid ON issues(component_uuid);
CREATE INDEX CONCURRENTLY idx_issues_creation_date ON issues(issue_creation_date);
CREATE INDEX CONCURRENTLY idx_snapshots_component_uuid ON snapshots(component_uuid);

-- Update statistics
ANALYZE;
```

### Storage Optimization

```hcl
# Use faster storage classes
variable "storage_configurations" {
  type = map(object({
    storage_class = string
    iops         = number
    throughput   = number
  }))

  default = {
    development = {
      storage_class = "gp2"
      iops         = 3000
      throughput   = 125
    }

    production = {
      storage_class = "gp3"
      iops         = 10000
      throughput   = 1000
    }
  }
}
```

### Analysis Performance

```properties
# sonar-project.properties optimization
sonar.exclusions=**/node_modules/**,**/vendor/**,**/target/**
sonar.test.exclusions=**/tests/**,**/*_test.go,**/*Test.java

# Limit analysis scope for large projects
sonar.sources=src/main
sonar.tests=src/test

# Parallel analysis (use with caution)
sonar.scanner.maxMemory=4096m
sonar.analysis.mode=incremental
```

### Network Optimization

```yaml
# Use faster networking
apiVersion: v1
kind: Service
metadata:
  name: sonarqube-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

## Backup & Recovery

### Database Backup

```bash
#!/bin/bash
# automated-backup.sh

# Set variables
NAMESPACE="sonarqube"
POD_NAME="sonarqube-postgresql-0"
DB_USER="sonarUser"
DB_NAME="sonarDB"
BACKUP_DIR="/backups/sonarqube"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform database backup
kubectl exec $POD_NAME -n $NAMESPACE -- \
  pg_dump -U $DB_USER -d $DB_NAME \
  --format=custom --compress=9 > $BACKUP_DIR/sonarqube_$DATE.dump

# Backup globals (users, roles, etc.)
kubectl exec $POD_NAME -n $NAMESPACE -- \
  pg_dumpall -U $DB_USER --globals-only > $BACKUP_DIR/globals_$DATE.sql

# Compress and encrypt backup
tar -czf $BACKUP_DIR/sonarqube_backup_$DATE.tar.gz \
  $BACKUP_DIR/sonarqube_$DATE.dump \
  $BACKUP_DIR/globals_$DATE.sql

gpg --cipher-algo AES256 --compress-algo 1 \
  --symmetric --output $BACKUP_DIR/sonarqube_backup_$DATE.tar.gz.gpg \
  $BACKUP_DIR/sonarqube_backup_$DATE.tar.gz

# Upload to S3 (optional)
aws s3 cp $BACKUP_DIR/sonarqube_backup_$DATE.tar.gz.gpg \
  s3://your-backup-bucket/sonarqube/

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.dump" -mtime +7 -delete
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: sonarqube_backup_$DATE.tar.gz.gpg"
```

### Configuration Backup

```bash
#!/bin/bash
# backup-configurations.sh

BACKUP_DIR="/backups/sonarqube-config"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup Kubernetes manifests
kubectl get all -n sonarqube -o yaml > $BACKUP_DIR/k8s-manifests_$DATE.yaml
kubectl get secrets -n sonarqube -o yaml > $BACKUP_DIR/secrets_$DATE.yaml
kubectl get configmaps -n sonarqube -o yaml > $BACKUP_DIR/configmaps_$DATE.yaml
kubectl get pvc -n sonarqube -o yaml > $BACKUP_DIR/pvc_$DATE.yaml

# Backup Helm values
helm get values sonarqube -n sonarqube > $BACKUP_DIR/helm-values_$DATE.yaml

# Backup SonarQube configuration
curl -u admin:$ADMIN_PASSWORD \
  "https://sonar.your-domain.com/api/settings/values" \
  > $BACKUP_DIR/sonarqube-settings_$DATE.json

curl -u admin:$ADMIN_PASSWORD \
  "https://sonar.your-domain.com/api/qualityprofiles/backup?language=java" \
  > $BACKUP_DIR/quality-profiles_$DATE.xml
```

### Persistent Volume Backup

```bash
#!/bin/bash
# backup-volumes.sh

# Backup using volume snapshots (AWS EBS)
PV_NAME=$(kubectl get pvc sonarqube-data -n sonarqube -o jsonpath='{.spec.volumeName}')
VOLUME_ID=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.awsElasticBlockStore.volumeID}' | cut -d'/' -f4)

# Create EBS snapshot
SNAPSHOT_ID=$(aws ec2 create-snapshot \
  --volume-id $VOLUME_ID \
  --description "SonarQube data backup $(date +%Y-%m-%d)" \
  --query 'SnapshotId' --output text)

echo "Created snapshot: $SNAPSHOT_ID"

# Tag snapshot for easier management
aws ec2 create-tags --resources $SNAPSHOT_ID \
  --tags Key=Name,Value="sonarqube-data-$(date +%Y%m%d)" \
         Key=Application,Value="SonarQube" \
         Key=Environment,Value="production"
```

### Disaster Recovery

```bash
#!/bin/bash
# disaster-recovery.sh

# 1. Restore database from backup
BACKUP_FILE="sonarqube_backup_20231201_120000.dump"

# Stop SonarQube
kubectl scale deployment sonarqube -n sonarqube --replicas=0

# Restore database
kubectl exec -i sonarqube-postgresql-0 -n sonarqube -- \
  dropdb -U sonarUser sonarDB

kubectl exec -i sonarqube-postgresql-0 -n sonarqube -- \
  createdb -U sonarUser sonarDB

kubectl exec -i sonarqube-postgresql-0 -n sonarqube -- \
  pg_restore -U sonarUser -d sonarDB < $BACKUP_FILE

# 2. Restore persistent volumes
# (If using volume snapshots)
aws ec2 create-volume --snapshot-id snap-1234567890abcdef0 \
  --availability-zone us-east-1a --volume-type gp3

# 3. Update PV to use new volume
kubectl patch pv sonarqube-data-pv \
  --patch '{"spec":{"awsElasticBlockStore":{"volumeID":"vol-new-volume-id"}}}'

# 4. Start SonarQube
kubectl scale deployment sonarqube -n sonarqube --replicas=1

# 5. Verify restoration
sleep 60
curl -s https://sonar.your-domain.com/api/system/health
```

### Automated Backup with CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sonarqube-backup
  namespace: sonarqube
spec:
  schedule: "0 2 * * *" # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres:11-alpine
              command:
                - /bin/sh
                - -c
                - |
                  # Perform database backup
                  pg_dump -h sonarqube-postgresql -U sonarUser -d sonarDB \
                    --format=custom --compress=9 > /backup/sonarqube_$(date +%Y%m%d_%H%M%S).dump

                  # Upload to S3
                  aws s3 cp /backup/sonarqube_*.dump s3://your-backup-bucket/sonarqube/

                  # Cleanup local files older than 3 days
                  find /backup -name "*.dump" -mtime +3 -delete
              env:
                - name: PGPASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: sonarqube-postgresql
                      key: postgresql-password
              volumeMounts:
                - name: backup-storage
                  mountPath: /backup
          volumes:
            - name: backup-storage
              persistentVolumeClaim:
                claimName: backup-pvc
          restartPolicy: OnFailure
```

## Migration Guide

### Migrating from External SonarQube

```bash
#!/bin/bash
# migrate-from-external.sh

# 1. Export data from external SonarQube
OLD_SONAR_URL="https://old-sonar.company.com"
NEW_SONAR_URL="https://sonar.your-domain.com"

# Export quality profiles
curl -u admin:password "$OLD_SONAR_URL/api/qualityprofiles/backup?language=java" \
  > java-quality-profile.xml

# Export projects configuration
curl -u admin:password "$OLD_SONAR_URL/api/projects/search" \
  > projects-list.json

# 2. Database migration (if same version)
# Stop old SonarQube
# Backup old database
pg_dump -U sonaruser -d sonardb > old-sonarqube.sql

# Import to new instance (after deployment)
kubectl exec -i sonarqube-postgresql-0 -n sonarqube -- \
  psql -U sonarUser -d sonarDB < old-sonarqube.sql

# 3. Import quality profiles to new instance
curl -u admin:new-password -X POST \
  "$NEW_SONAR_URL/api/qualityprofiles/restore" \
  -F "backup=@java-quality-profile.xml"
```

### Version Upgrade

```bash
#!/bin/bash
# upgrade-sonarqube.sh

# Current version: 10.6 -> New version: 10.7

# 1. Backup current installation
./backup-configurations.sh
./automated-backup.sh

# 2. Update Terraform configuration
# In variables.tf or main.tf:
# chart_version = "10.7.0+3598"

# 3. Plan and apply changes
terraform plan
terraform apply

# 4. Monitor upgrade progress
kubectl rollout status deployment/sonarqube -n sonarqube

# 5. Verify upgrade
curl -s https://sonar.your-domain.com/api/system/info | jq '.System.Version'

# 6. Test functionality
# - Login with OIDC
# - Run sample analysis
# - Check quality profiles
# - Verify webhooks
```

### Multi-Environment Migration

```hcl
# Migrate from single to multi-environment setup

# Before: Single production instance
module "sonarqube" {
  source = "./modules/kubernetes/sonarqube"
  # ... configuration
}

# After: Multi-environment setup
module "sonarqube_dev" {
  source = "./modules/kubernetes/sonarqube"

  namespace           = "sonarqube-dev"
  sonarqube_subdomain = "sonar-dev"
  environment         = "dev"

  sonarqube_resources = {
    requests = { cpu = "500m", memory = "2Gi" }
    limits   = { cpu = "2", memory = "8Gi" }
  }

  storage_size = "20Gi"
}

module "sonarqube_staging" {
  source = "./modules/kubernetes/sonarqube"

  namespace           = "sonarqube-staging"
  sonarqube_subdomain = "sonar-staging"
  environment         = "staging"

  sonarqube_resources = {
    requests = { cpu = "1", memory = "4Gi" }
    limits   = { cpu = "4", memory = "16Gi" }
  }

  storage_size = "50Gi"
}

module "sonarqube_prod" {
  source = "./modules/kubernetes/sonarqube"

  namespace           = "sonarqube-prod"
  sonarqube_subdomain = "sonar"
  environment         = "prod"

  sonarqube_resources = {
    requests = { cpu = "2", memory = "8Gi" }
    limits   = { cpu = "8", memory = "32Gi" }
  }

  storage_size = "100Gi"
}
```

---

## Summary

This comprehensive SonarQube Terraform module provides:

✅ **Complete SonarQube deployment** with official Helm chart  
✅ **Cognito OIDC integration** for seamless authentication  
✅ **PostgreSQL database** with persistent storage  
✅ **Production-ready configuration** with monitoring and security  
✅ **CI/CD integration examples** for popular platforms  
✅ **Comprehensive documentation** for deployment and maintenance  
✅ **Troubleshooting guides** for common issues  
✅ **Performance tuning** recommendations  
✅ **Backup and recovery** procedures  
✅ **Security best practices** implementation

For questions or issues, refer to the troubleshooting section or consult the [SonarQube official documentation](https://docs.sonarqube.org/).

---

**Version**: 2.0.0  
**Last Updated**: November 2024  
**Terraform Version**: 1.0+  
**SonarQube Version**: 10.7 Community Edition  
**License**: MIT
