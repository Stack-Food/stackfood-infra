# 🚀 StackFood - Complete Deployment Guide

Guia completo para deploy de toda a infraestrutura e microserviços StackFood.

---

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Infrastructure Deployment (Terraform)](#%EF%B8%8F-infrastructure-deployment)
3. [Microservices Deployment (GitOps)](#-microservices-deployment)
4. [Messaging Configuration (SNS/SQS)](#-messaging-configuration)
5. [Verification & Testing](#-verification--testing)
6. [Troubleshooting](#-troubleshooting)

---

## 🎯 Prerequisites

### Required Tools

```bash
terraform >= 1.0.0
aws-cli >= 2.0
kubectl >= 1.25
argocd-cli >= 2.0
git >= 2.30
jq >= 1.6
```

### AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
```

### Verify Access

```bash
aws sts get-caller-identity
aws eks list-clusters
```

---

## ☁️ Infrastructure Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/Stack-Food/stackfood-infra.git
cd stackfood-infra/terraform/aws/main
```

### Step 2: Configure Variables

Edit `terraform/aws/env/prod.tfvars` or create your own:

```hcl
# General
environment = "prod"
domain_name = "stackfood.com.br"

# EKS
eks_cluster_name = "stackfood-eks"
kubernetes_version = "1.33"

# Cloudflare
cloudflare_zone_id = "your-zone-id"
cloudflare_api_token = "your-api-token"

# Team users (optional)
team_users = {
  "user1" = {
    name   = "John Doe"
    email  = "john@example.com"
    groups = ["argocd", "grafana"]
  }
}
```

### Step 3: Apply Terraform

```bash
terraform init
terraform plan -var-file="../env/prod.tfvars"
terraform apply -var-file="../env/prod.tfvars"
```

**Expected Resources:**
- ✅ VPC with public/private subnets
- ✅ EKS Cluster (1.33)
- ✅ RDS PostgreSQL instances
- ✅ DynamoDB tables
- ✅ SNS Topics (4)
- ✅ SQS Queues (4 + 4 DLQs)
- ✅ API Gateway with VPC Link
- ✅ Lambda functions
- ✅ Cognito User Pools
- ✅ ArgoCD + Grafana
- ✅ NGINX Ingress Controller

**Deployment Time:** ~25-30 minutes

### Step 4: Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name stackfood-eks
kubectl get nodes
kubectl get namespaces
```

---

## 🐳 Microservices Deployment

### Microservices Overview

| Service | Port | Namespace | Repository |
|---------|------|-----------|------------|
| Customers | 8084 | customers | [stackfood-api-customers](https://github.com/Stack-Food/stackfood-api-customers) |
| Products | 8080 | products | [stackfood-api-product](https://github.com/Stack-Food/stackfood-api-product) |
| Orders | 8081 | orders | [stackfood-api-orders](https://github.com/Stack-Food/stackfood-api-orders) |
| Payments | 8082 | payments | [stackfood-api-payments](https://github.com/Stack-Food/stackfood-api-payments) |
| Production | 8083 | production | [stackfood-api-production](https://github.com/Stack-Food/stackfood-api-production) |

### Step 1: Create Image Pull Secrets

Create in each namespace:

```bash
for ns in customers products orders payments production; do
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=<GITHUB_USER> \
    --docker-password=<GITHUB_PAT> \
    --docker-email=<EMAIL> \
    -n $ns
done
```

### Step 2: Deploy with ArgoCD

#### Option A: Automated (Recommended)

```bash
cd stackfood-infra/scripts
chmod +x deploy-all-microservices.sh
./deploy-all-microservices.sh
```

#### Option B: Manual

```bash
# Customers
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-customers/main/k8s/argocd-application.yaml

# Products
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-product/main/k8s/argocd-application.yaml

# Orders
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-orders/main/k8s/argocd-application.yaml

# Payments
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-payments/main/k8s/argocd-application.yaml

# Production
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-production/main/k8s/argocd-application.yaml
```

### Step 3: Verify ArgoCD Applications

```bash
kubectl get applications -n argocd

# Expected output:
# NAME         SYNC STATUS   HEALTH STATUS
# customers    Synced        Healthy
# products     Synced        Healthy
# orders       Synced        Healthy
# payments     Synced        Healthy
# production   Synced        Healthy
```

### Step 4: Check Pods

```bash
kubectl get pods -A | grep stackfood

# All pods should be Running
```

---

## 📬 Messaging Configuration

### Architecture

```
Orders → OrderEvents SNS Topic
            ↓
    ┌───────┴───────┐
    ↓               ↓
Payments Queue  Production Queue
    ↓               ↓
Payments        Production
    ↓               ↓
Payment SNS     Production SNS
    ↓               ↓
Orders Queue    Orders Queue
```

### Step 1: Get Terraform Outputs

After infrastructure deployment, get SNS/SQS values:

```bash
cd stackfood-infra/terraform/aws/main

# Get all ConfigMap values
terraform output -json configmap_values | jq '.'
```

**Example Output:**
```json
{
  "customers": {
    "AWS__SNS__CustomerEventsTopicArn": "arn:aws:sns:us-east-1:123:stackfood-customer-events"
  },
  "orders": {
    "AWS__SNS__OrderCreatedTopicArn": "arn:aws:sns:us-east-1:123:stackfood-order-events",
    "AWS__SQS__PaymentEventsQueueUrl": "https://sqs.us-east-1.amazonaws.com/123/stackfood-order-payment-events-queue",
    "AWS__SQS__ProductionEventsQueueUrl": "https://sqs.us-east-1.amazonaws.com/123/stackfood-order-production-events-queue"
  },
  "payments": {
    "AWS__SNS__PaymentEventsTopicArn": "arn:aws:sns:us-east-1:123:stackfood-payment-events",
    "AWS__SQS__OrderEventsQueueUrl": "https://sqs.us-east-1.amazonaws.com/123/stackfood-payment-events-queue"
  },
  "production": {
    "AWS__SNS__TopicArn": "arn:aws:sns:us-east-1:123:stackfood-production-events",
    "AWS__SQS__QueueUrl": "https://sqs.us-east-1.amazonaws.com/123/stackfood-production-events-queue"
  }
}
```

### Step 2: Update ConfigMaps

For each microservice repository, update `k8s/prod/configmap.yaml`:

#### Customers
```bash
cd stackfood-api-customers
# Edit k8s/prod/configmap.yaml
AWS__SNS__CustomerEventsTopicArn: "<PASTE_VALUE>"
git add k8s/prod/configmap.yaml
git commit -m "Update SNS ARN from Terraform"
git push
```

#### Orders
```bash
cd stackfood-api-orders
# Edit k8s/prod/configmap.yaml
AWS__SNS__OrderCreatedTopicArn: "<VALUE>"
AWS__SQS__PaymentEventsQueueUrl: "<VALUE>"
AWS__SQS__ProductionEventsQueueUrl: "<VALUE>"
git add k8s/prod/configmap.yaml
git commit -m "Update SNS/SQS from Terraform"
git push
```

#### Payments
```bash
cd stackfood-api-payments
# Edit k8s/prod/configmap.yaml
AWS__SNS__PaymentEventsTopicArn: "<VALUE>"
AWS__SQS__OrderEventsQueueUrl: "<VALUE>"
git add k8s/prod/configmap.yaml
git commit -m "Update SNS/SQS from Terraform"
git push
```

#### Production
```bash
cd stackfood-api-production
# Edit k8s/prod/configmap.yaml
AWS__SNS__TopicArn: "<VALUE>"
AWS__SQS__QueueUrl: "<VALUE>"
git add k8s/prod/configmap.yaml
git commit -m "Update SNS/SQS from Terraform"
git push
```

### Step 3: ArgoCD Auto-Sync

ArgoCD will automatically detect changes and restart pods:

```bash
# Watch ArgoCD sync
kubectl get applications -n argocd -w

# Force sync if needed
argocd app sync orders
argocd app sync payments
argocd app sync production
```

---

## ✅ Verification & Testing

### 1. Check All Pods

```bash
kubectl get pods -A | grep stackfood

# Expected: All Running
stackfood-customers-xxx   1/1   Running
stackfood-products-xxx    1/1   Running
stackfood-orders-xxx      1/1   Running
stackfood-payments-xxx    1/1   Running
stackfood-production-xxx  1/1   Running
```

### 2. Check Services

```bash
kubectl get svc -A | grep stackfood

# All should have ClusterIP assigned
```

### 3. Test API Gateway Routes

```bash
# Get API Gateway URL
cd terraform/aws/main
API_URL=$(terraform output -json api_gateway_stage_invoke_url | jq -r '.')

# Test routes
curl $API_URL/customers/health
curl $API_URL/products/health
curl $API_URL/orders/health
curl $API_URL/payments/health
curl $API_URL/production/health
```

### 4. Test Messaging

```bash
# Create test order
curl -X POST $API_URL/orders/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "test-123",
    "items": [{"productId": "prod-001", "quantity": 2}]
  }'

# Check SQS queues
aws sqs get-queue-attributes \
  --queue-url $(terraform output -json configmap_values | jq -r '.payments."AWS__SQS__OrderEventsQueueUrl"') \
  --attribute-names ApproximateNumberOfMessages
```

### 5. Check Logs

```bash
kubectl logs -f deployment/stackfood-orders -n orders
kubectl logs -f deployment/stackfood-payments -n payments | grep -i "sqs\|sns"
```

---

## 🔧 Troubleshooting

### Pods Not Starting

**Problem:** Pods stuck in `ImagePullBackOff`

**Solution:**
```bash
# Check image pull secret
kubectl get secret ghcr-secret -n <namespace>

# Recreate if needed
kubectl delete secret ghcr-secret -n <namespace>
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<USER> \
  --docker-password=<PAT> \
  -n <namespace>

# Restart deployment
kubectl rollout restart deployment/stackfood-<service> -n <namespace>
```

### ConfigMap Not Updating

**Problem:** Pods not picking up new ConfigMap values

**Solution:**
```bash
# Delete pods to force recreation
kubectl delete pod -l app=stackfood-orders -n orders

# Or rollout restart
kubectl rollout restart deployment/stackfood-orders -n orders
```

### API Gateway 502 Errors

**Problem:** API Gateway returns 502 Bad Gateway

**Solution:**
```bash
# Check VPC Link status
aws apigateway get-vpc-links

# Check NLB
kubectl get svc -n ingress-nginx

# Check pod health
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### Messages Not Being Received

**Problem:** SQS messages not consumed

**Solution:**
```bash
# Check AWS credentials in pod
kubectl exec -it deployment/stackfood-payments -n payments -- env | grep AWS

# Check queue permissions
aws sqs get-queue-attributes \
  --queue-url <QUEUE_URL> \
  --attribute-names Policy

# Check dead letter queue
aws sqs receive-message \
  --queue-url <DLQ_URL> \
  --max-number-of-messages 10
```

### ArgoCD Out of Sync

**Problem:** ArgoCD application shows OutOfSync

**Solution:**
```bash
# Get details
argocd app get <app-name>

# Sync manually
argocd app sync <app-name>

# Hard refresh
argocd app sync <app-name> --hard-refresh
```

---

## 📊 Monitoring

### CloudWatch Metrics

```bash
# SNS Published Messages
aws cloudwatch get-metric-statistics \
  --namespace AWS/SNS \
  --metric-name NumberOfMessagesPublished \
  --dimensions Name=TopicName,Value=stackfood-order-events \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# SQS Queue Depth
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateNumberOfMessagesVisible \
  --dimensions Name=QueueName,Value=stackfood-payment-events-queue \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Access ArgoCD

```bash
# Get URL
terraform output -json argocd_access_info

# Port-forward (if needed)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080
# User: stackfood
# Password: Fiap@2025
```

### Access Grafana

```bash
# Get URL
terraform output -json grafana_access_info

# Open: https://grafana.stackfood.com.br
# Login with Cognito SSO
```

---

## 🔄 Rollback Plan

If issues occur:

```bash
# Rollback specific application
argocd app rollback <app-name>

# Destroy messaging infrastructure
terraform destroy -target=module.sns -target=module.sqs

# Destroy all infrastructure
terraform destroy
```

---

## ✅ Deployment Checklist

- [ ] Terraform applied successfully
- [ ] EKS cluster accessible
- [ ] ArgoCD accessible
- [ ] Image pull secrets created
- [ ] All 5 microservices deployed
- [ ] All pods Running
- [ ] ConfigMaps updated with SNS/SQS values
- [ ] API Gateway routes working
- [ ] End-to-end test successful
- [ ] Monitoring configured

---

**Total Deployment Time:** ~45 minutes

**Documentation:**
- Architecture details: [ARCHITECTURE.md](ARCHITECTURE.md)
- GitOps summary: [GITOPS-SUMMARY.md](GITOPS-SUMMARY.md)
- Main README: [README.md](README.md)

---

🚀 **StackFood - Production Ready!**
