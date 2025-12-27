# 🏗️ StackFood - Technical Architecture

Documentação técnica detalhada da arquitetura de microserviços, API Gateway e mensageria.

---

## 📋 Table of Contents

1. [System Overview](#-system-overview)
2. [API Gateway Architecture](#-api-gateway-architecture)
3. [Event-Driven Messaging](#-event-driven-messaging)
4. [Microservices Communication](#-microservices-communication)
5. [Security & IAM](#-security--iam)
6. [Scalability & Performance](#-scalability--performance)

---

## 🌐 System Overview

### Complete Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet / Client                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Cloudflare    │
                    │   (DNS + CDN)   │
                    └────────┬────────┘
                             │
            ┌────────────────▼────────────────┐
            │      AWS API Gateway            │
            │   api.stackfood.com.br         │
            ├─────────────┬──────────────────┤
            │             │                   │
     ┌──────▼──────┐     │            ┌─────▼──────┐
     │   Lambda    │     │            │  VPC Link  │
     │   /auth     │     │            └─────┬──────┘
     │  /customer  │     │                  │
     └──────┬──────┘     │            ┌─────▼──────┐
            │            │            │    NLB     │
     ┌──────▼──────┐     │            └─────┬──────┘
     │  Cognito    │     │                  │
     │ User Pools  │     │            ┌─────▼──────┐
     └─────────────┘     │            │   NGINX    │
                         │            │  Ingress   │
                         │            └─────┬──────┘
                         │                  │
                         │      ┌───────────┼───────────┬───────────┐
                         │      │           │           │           │
                    ┌────▼──────▼┐    ┌────▼────┐ ┌────▼────┐ ┌────▼────┐
                    │  Customers  │    │ Orders  │ │Payments │ │Products │
                    │    :8084    │    │  :8081  │ │  :8082  │ │  :8080  │
                    └─────┬───────┘    └────┬────┘ └────┬────┘ └─────────┘
                          │                 │           │
                    ┌─────▼─────┐     ┌────▼───┐  ┌────▼────┐
                    │  RDS PG   │     │  SNS   │  │DynamoDB │
                    │ Customers │     │  SQS   │  │Payments │
                    └───────────┘     └────────┘  └─────────┘
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Edge** | Cloudflare | CDN, DDoS protection, DNS |
| **Gateway** | AWS API Gateway | Routing, throttling, monitoring |
| **Auth** | Lambda + Cognito | Authentication, user management |
| **Orchestration** | EKS (Kubernetes 1.33) | Container orchestration |
| **Routing** | NGINX Ingress | L7 load balancing |
| **Services** | .NET 8 (ASP.NET Core) | Microservices |
| **Messaging** | SNS + SQS | Event-driven communication |
| **Database** | PostgreSQL (RDS) | Relational data |
| **NoSQL** | DynamoDB | Payment transactions |
| **GitOps** | ArgoCD | Continuous deployment |

---

## 🚪 API Gateway Architecture

### Hybrid Routing Model

```
API Gateway
    ├── /auth (POST) → Lambda (AWS_PROXY)
    ├── /customer (POST) → Lambda (AWS_PROXY)
    └── /{service}/{proxy+} (ANY) → VPC Link (HTTP_PROXY)
            ├── /customers/* → stackfood-customers:8084
            ├── /products/* → stackfood-products:8080
            ├── /orders/* → stackfood-orders:8081
            ├── /payments/* → stackfood-payments:8082
            └── /production/* → stackfood-production:8083
```

### Lambda Integration (AWS_PROXY)

**Routes:**
- `POST /auth` - User authentication via Cognito
- `POST /customer` - Customer creation

**Flow:**
```
Client → API Gateway → Lambda → Cognito
                         ↓
                    PostgreSQL
                         ↓
                    Return JWT
```

**Features:**
- ✅ Automatic request/response transformation
- ✅ Lambda error handling
- ✅ CloudWatch Logs integration
- ✅ Cognito integration

### VPC Link Integration (HTTP_PROXY)

**Routes:**
- `ANY /customers/{proxy+}` → `http://stackfood-customers.customers.svc.cluster.local:8084/{proxy}`
- `ANY /products/{proxy+}` → `http://stackfood-products.products.svc.cluster.local:8080/{proxy}`
- `ANY /orders/{proxy+}` → `http://stackfood-orders.orders.svc.cluster.local:8081/{proxy}`
- `ANY /payments/{proxy+}` → `http://stackfood-payments.payments.svc.cluster.local:8082/{proxy}`
- `ANY /production/{proxy+}` → `http://stackfood-production.production.svc.cluster.local:8083/{proxy}`

**Flow:**
```
Client → API Gateway → VPC Link → NLB → NGINX Ingress → K8s Service → Pod
```

**Features:**
- ✅ Private network connectivity
- ✅ Path parameter forwarding
- ✅ Query string preservation
- ✅ Header forwarding
- ✅ HTTP method passthrough (GET, POST, PUT, DELETE, PATCH)

### Example Requests

```bash
# Auth via Lambda
curl -X POST https://api.stackfood.com.br/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"user@example.com","password":"Pass123!"}'

# Customer creation via Lambda
curl -X POST https://api.stackfood.com.br/customer \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Orders via VPC Link
curl https://api.stackfood.com.br/orders/api/orders
curl -X POST https://api.stackfood.com.br/orders/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":"123","items":[...]}'

# Products via VPC Link
curl https://api.stackfood.com.br/products/api/products
```

### API Gateway Configuration

**Deployment Triggers:**
```hcl
redeployment = sha1(jsonencode([
  # Lambda routes
  aws_api_gateway_resource.auth,
  aws_api_gateway_method.auth_post,
  aws_api_gateway_integration.auth_lambda,

  # Microservices routes
  aws_api_gateway_resource.customers,
  aws_api_gateway_method.customers_any,
  aws_api_gateway_integration.customers_vpc_link,
  # ... etc for all services
]))
```

**Stage Configuration:**
```hcl
stage_name = "v1"
invoke_url = "https://<api-id>.execute-api.us-east-1.amazonaws.com/v1"
custom_domain = "api.stackfood.com.br"
```

---

## 📬 Event-Driven Messaging

### SNS Topics

| Topic Name | Publisher | Purpose | Subscribers |
|------------|-----------|---------|-------------|
| `stackfood-customer-events` | Customers | Customer lifecycle events | None (future use) |
| `stackfood-order-events` | Orders | Order lifecycle events | Payments Queue, Production Queue |
| `stackfood-payment-events` | Payments | Payment status updates | Orders Queue |
| `stackfood-production-events` | Production | Production status updates | Orders Queue |

### SQS Queues

| Queue Name | Consumer | Source Topic | Max Retries | DLQ |
|------------|----------|--------------|-------------|-----|
| `stackfood-payment-events-queue` | Payments | order-events | 3 | ✅ |
| `stackfood-production-events-queue` | Production | order-events | 3 | ✅ |
| `stackfood-order-payment-events-queue` | Orders | payment-events | 3 | ✅ |
| `stackfood-order-production-events-queue` | Orders | production-events | 3 | ✅ |

### Queue Configuration

```hcl
visibility_timeout_seconds = 300  # 5 minutes
receive_wait_time_seconds  = 10   # Long polling
message_retention_seconds  = 1209600  # 14 days
max_receive_count          = 3    # DLQ threshold
sqs_managed_sse_enabled    = true # Encryption
```

### Filter Policies

**Order Events → Payments Queue:**
```json
{
  "eventType": ["OrderCreated", "OrderCancelled"]
}
```

**Order Events → Production Queue:**
```json
{
  "eventType": ["OrderCreated", "OrderConfirmed"]
}
```

**Payment Events → Orders Queue:**
```json
{
  "eventType": ["PaymentApproved", "PaymentFailed", "PaymentRefunded"]
}
```

**Production Events → Orders Queue:**
```json
{
  "eventType": ["ProductionStarted", "ProductionCompleted", "ProductionFailed"]
}
```

### Message Formats

#### OrderCreated Event
```json
{
  "eventType": "OrderCreated",
  "orderId": "9d90b301-535e-4ced-8dd2-19ea44652edf",
  "customerId": "123e4567-e89b-12d3-a456-426614174000",
  "items": [
    {
      "productId": "prod-001",
      "quantity": 2,
      "price": 15.99
    }
  ],
  "totalAmount": 31.98,
  "timestamp": "2025-12-26T10:30:00Z"
}
```

#### PaymentApproved Event
```json
{
  "eventType": "PaymentApproved",
  "orderId": "9d90b301-535e-4ced-8dd2-19ea44652edf",
  "paymentId": "pay-789",
  "amount": 31.98,
  "paymentMethod": "credit_card",
  "timestamp": "2025-12-26T10:31:00Z"
}
```

### Event Flow Scenarios

#### Successful Order Flow

```
1. Customer creates order
   Orders publishes: OrderCreated → order-events topic

2. Fanout to consumers
   order-events → payments-queue (filter: OrderCreated)
   order-events → production-queue (filter: OrderCreated)

3. Payment processing
   Payments consumes from payments-queue
   Payments publishes: PaymentApproved → payment-events topic

4. Order status update
   payment-events → orders-payment-queue
   Orders consumes and updates status to "Paid"

5. Production start
   Production consumes from production-queue
   Production publishes: ProductionStarted → production-events topic

6. Order status update
   production-events → orders-production-queue
   Orders consumes and updates status to "In Production"

7. Production completion
   Production publishes: ProductionCompleted → production-events topic
   Orders consumes and updates status to "Ready"
```

#### Failed Payment Flow

```
1. Customer creates order
   Orders publishes: OrderCreated

2. Payment processing fails
   Payments publishes: PaymentFailed → payment-events topic

3. Order cancellation
   Orders consumes PaymentFailed
   Orders updates status to "Payment Failed"
   Orders publishes: OrderCancelled → order-events topic

4. Cleanup
   Production receives OrderCancelled (via filter policy)
   Production cancels any pending work
```

---

## 🔄 Microservices Communication

### Internal DNS Resolution

All microservices communicate via Kubernetes internal DNS:

```
Format: <service-name>.<namespace>.svc.cluster.local:<port>
```

| Service | Internal DNS | Port |
|---------|-------------|------|
| Customers | `stackfood-customers.customers.svc.cluster.local` | 8084 |
| Products | `stackfood-products.products.svc.cluster.local` | 8080 |
| Orders | `stackfood-orders.orders.svc.cluster.local` | 8081 |
| Payments | `stackfood-payments.payments.svc.cluster.local` | 8082 |
| Production | `stackfood-production.production.svc.cluster.local` | 8083 |

### Service Types

All microservices use `ClusterIP` (internal-only access):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: stackfood-orders
  namespace: orders
spec:
  type: ClusterIP
  ports:
    - port: 8081
      targetPort: 8081
      protocol: TCP
```

### Inter-Service Communication Patterns

**Synchronous (HTTP):**
- Orders → Products (validate product IDs)
- Orders → Customers (validate customer)

**Asynchronous (SNS/SQS):**
- Orders → Payments (payment processing)
- Orders → Production (production queue)
- Payments → Orders (payment status)
- Production → Orders (production status)

---

## 🔒 Security & IAM

### IAM Permissions for Microservices

**Required Permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "arn:aws:sns:*:*:stackfood-*-events"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ],
      "Resource": [
        "arn:aws:sqs:*:*:stackfood-*-queue"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:*:*:table/stackfood-payments"
      ]
    }
  ]
}
```

### Queue Policies

Each SQS queue has automatic policy allowing SNS to send messages:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:stackfood-payment-events-queue",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:*:*:stackfood-order-events"
        }
      }
    }
  ]
}
```

### Network Security

**VPC Configuration:**
- Private subnets for EKS nodes
- Public subnets for NLB
- NAT Gateways for outbound traffic
- Security groups per service

**API Gateway Security:**
- Regional endpoint (not Edge)
- VPC Link for private communication
- Rate limiting: 10,000 req/s
- Burst limit: 5,000 req

---

## 📈 Scalability & Performance

### Horizontal Pod Autoscaling (HPA)

All microservices have HPA configured:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Resource Limits

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### SQS Performance Tuning

- **Long Polling:** 10 seconds (reduces empty receives)
- **Batch Receive:** Up to 10 messages per call
- **Visibility Timeout:** 5 minutes
- **Message Retention:** 14 days
- **Dead Letter Queue:** After 3 failed attempts

### CloudWatch Metrics

**API Gateway:**
- Count, 4XXError, 5XXError
- Latency, IntegrationLatency
- CacheHitCount, CacheMissCount

**SNS:**
- NumberOfMessagesPublished
- NumberOfNotificationsFailed

**SQS:**
- ApproximateNumberOfMessagesVisible
- ApproximateAgeOfOldestMessage
- NumberOfMessagesSent/Received
- NumberOfMessagesDeleted

### Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| API Latency (p99) | < 500ms | TBD |
| Message Processing | < 1s | TBD |
| Pod Startup Time | < 30s | TBD |
| HPA Scale-up Time | < 2min | TBD |

---

## 📚 Technical References

### API Gateway
- [VPC Link Setup](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [HTTP_PROXY Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/setup-http-integrations.html)
- [Proxy+ Parameter](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-method-settings-method-request.html#api-gateway-proxy-resource)

### Messaging
- [SNS Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)
- [SQS Best Practices](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-best-practices.html)
- [DLQ Configuration](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)

### Kubernetes
- [Service DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [HPA Configuration](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

**Last Updated:** 2025-12-26
**Version:** 2.0.0
**Maintainer:** DevOps Team

---

🏗️ **StackFood - Technical Architecture Documentation**
