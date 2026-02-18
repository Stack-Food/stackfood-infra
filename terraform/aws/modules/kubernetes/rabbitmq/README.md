# RabbitMQ Module

## Overview

This module deploys RabbitMQ message broker in Amazon EKS using the official Bitnami Helm chart. RabbitMQ runs on a **dedicated node group** with taints to ensure workload isolation.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster                               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Dedicated RabbitMQ Node Group                         │ │
│  │  - Taint: workload=rabbitmq:NoSchedule                 │ │
│  │  - Instance Type: t3.medium (recommended)              │ │
│  │                                                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │ │
│  │  │  RabbitMQ    │  │  RabbitMQ    │  │  RabbitMQ    │ │ │
│  │  │  Pod 1       │  │  Pod 2       │  │  Pod 3       │ │ │
│  │  │  (Master)    │  │  (Mirror)    │  │  (Mirror)    │ │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │ │
│  │         │                  │                  │         │ │
│  │         └──────────────────┴──────────────────┘         │ │
│  │                    ClusterIP Service                    │ │
│  └────────────────────────────┬────────────────────────────┘ │
│                               │                               │
│  ┌────────────────────────────┼────────────────────────────┐ │
│  │  Application Node Group    │                            │ │
│  │                            │                            │ │
│  │  ┌──────────────┐   ┌──────▼──────┐   ┌──────────────┐│ │
│  │  │  Orders API  │──▶│  RabbitMQ   │◀──│ Payments API ││ │
│  │  └──────────────┘   │  Service    │   └──────────────┘│ │
│  │                     └─────────────┘                    │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Features

- ✅ **Dedicated Node Group**: Runs on isolated nodes with taints
- ✅ **High Availability**: 3 replicas with anti-affinity rules
- ✅ **Persistent Storage**: EBS volumes for message persistence
- ✅ **Management UI**: Web interface for monitoring (port 15672)
- ✅ **Clustering**: Automatic peer discovery via Kubernetes
- ✅ **Monitoring**: Prometheus metrics enabled
- ✅ **Security**: Non-root containers, read-only filesystem
- ✅ **Auto-scaling**: HPA-ready (can be configured)

## Enabled Plugins

- `rabbitmq_management` - Web management UI
- `rabbitmq_peer_discovery_k8s` - Kubernetes-based clustering
- `rabbitmq_prometheus` - Prometheus metrics exporter

## Usage

```hcl
module "rabbitmq" {
  source = "../modules/kubernetes/rabbitmq"

  environment = var.environment
  namespace   = "messaging"
  
  # Authentication
  rabbitmq_password      = var.rabbitmq_password
  rabbitmq_erlang_cookie = var.rabbitmq_erlang_cookie
  
  # Cluster configuration
  replicas = 3
  
  # Node selector for dedicated nodes
  node_selector_key   = "workload"
  node_selector_value = "rabbitmq"
  
  # Storage
  storage_size  = "20Gi"
  storage_class = "gp2"
  
  # Resources
  rabbitmq_resources = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
  
  tags = var.tags
}
```

## Prerequisites

### 1. Dedicated Node Group in EKS

The EKS cluster must have a dedicated node group for RabbitMQ:

```hcl
# In your EKS module configuration
rabbitmq_node_group = {
  name           = "rabbitmq"
  instance_types = ["t3.medium"]
  desired_size   = 3
  min_size       = 3
  max_size       = 5
  
  labels = {
    workload = "rabbitmq"
  }
  
  taints = [{
    key    = "workload"
    value  = "rabbitmq"
    effect = "NO_SCHEDULE"
  }]
}
```

### 2. EBS CSI Driver

Required for persistent volumes:

```bash
# Check if installed
kubectl get pods -n kube-system | grep ebs-csi

# If not installed, enable in EKS module:
enable_ebs_csi_driver = true
```

## Accessing RabbitMQ

### From Applications (Internal)

```bash
# AMQP Connection URL
amqp://admin:password@rabbitmq.messaging.svc.cluster.local:5672/

# Management API
http://rabbitmq.messaging.svc.cluster.local:15672
```

### Connection Example (C#/.NET)

```csharp
var factory = new ConnectionFactory
{
    HostName = "rabbitmq.messaging.svc.cluster.local",
    Port = 5672,
    UserName = "admin",
    Password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD"),
    VirtualHost = "/"
};

using var connection = factory.CreateConnection();
using var channel = connection.CreateModel();
```

### Management UI (Port-Forward)

```bash
# Port forward to access management UI
kubectl port-forward -n messaging svc/rabbitmq 15672:15672

# Open browser: http://localhost:15672
# Username: admin
# Password: <from secret>
```

### Get Admin Password

```bash
kubectl get secret -n messaging rabbitmq-auth \
  -o jsonpath="{.data.rabbitmq-password}" | base64 --decode
```

## Configuration Reference

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `namespace` | string | `"messaging"` | Kubernetes namespace |
| `replicas` | number | `3` | Number of RabbitMQ pods |
| `rabbitmq_username` | string | `"admin"` | Admin username |
| `rabbitmq_password` | string | - | Admin password (required) |
| `rabbitmq_erlang_cookie` | string | - | Erlang cookie for clustering (required) |
| `storage_size` | string | `"20Gi"` | Persistent volume size |
| `storage_class` | string | `"gp2"` | Storage class name |
| `node_selector_key` | string | `"workload"` | Node selector label key |
| `node_selector_value` | string | `"rabbitmq"` | Node selector label value |

### Outputs

| Output | Description |
|--------|-------------|
| `namespace` | RabbitMQ namespace |
| `service_name` | Internal DNS name |
| `amqp_url` | AMQP connection URL |
| `management_url` | Management UI URL |
| `connection_info` | Complete connection details |

## Monitoring

### Prometheus Metrics

RabbitMQ exposes metrics on port 9419:

```yaml
# ServiceMonitor example
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rabbitmq
  namespace: messaging
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: rabbitmq
  endpoints:
    - port: metrics
      interval: 30s
```

### Key Metrics

- `rabbitmq_queue_messages` - Messages in queue
- `rabbitmq_queue_consumers` - Active consumers
- `rabbitmq_channel_count` - Open channels
- `rabbitmq_connection_count` - Active connections

## High Availability

### Clustering

RabbitMQ automatically forms a cluster using Kubernetes peer discovery:

```bash
# Check cluster status
kubectl exec -n messaging rabbitmq-0 -- rabbitmqctl cluster_status
```

### Message Mirroring

Configure HA policies for critical queues:

```bash
kubectl exec -n messaging rabbitmq-0 -- \
  rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all"}'
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n messaging
kubectl describe pod -n messaging rabbitmq-0
```

### View Logs

```bash
kubectl logs -n messaging rabbitmq-0 -f
```

### Check Node Selector

```bash
# Verify nodes have the correct label
kubectl get nodes --show-labels | grep rabbitmq

# Verify pods are scheduled correctly
kubectl get pods -n messaging -o wide
```

### Common Issues

#### Pods Stuck in Pending

```bash
# Check events
kubectl get events -n messaging --sort-by='.lastTimestamp'

# Likely causes:
# 1. No nodes with matching label/taint
# 2. Insufficient resources
# 3. PVC binding issues
```

#### Cluster Formation Issues

```bash
# Check Erlang cookie consistency
kubectl exec -n messaging rabbitmq-0 -- cat /var/lib/rabbitmq/.erlang.cookie
kubectl exec -n messaging rabbitmq-1 -- cat /var/lib/rabbitmq/.erlang.cookie

# Force cluster formation
kubectl exec -n messaging rabbitmq-0 -- rabbitmqctl reset
kubectl exec -n messaging rabbitmq-0 -- rabbitmqctl start_app
```

## Security Best Practices

1. **Use Strong Passwords**: Generate random passwords
2. **Rotate Erlang Cookie**: Change periodically
3. **Network Policies**: Restrict access to specific namespaces
4. **TLS**: Enable for production environments
5. **RBAC**: Limit service account permissions

## Resource Sizing

### Small (Development)

```hcl
replicas = 1
instance_type = "t3.small"
storage_size = "10Gi"
resources = {
  requests = { cpu = "250m", memory = "512Mi" }
  limits   = { cpu = "1000m", memory = "1Gi" }
}
```

### Medium (Production)

```hcl
replicas = 3
instance_type = "t3.medium"
storage_size = "20Gi"
resources = {
  requests = { cpu = "500m", memory = "1Gi" }
  limits   = { cpu = "2000m", memory = "2Gi" }
}
```

### Large (High Traffic)

```hcl
replicas = 5
instance_type = "t3.large"
storage_size = "50Gi"
resources = {
  requests = { cpu = "1000m", memory = "2Gi" }
  limits   = { cpu = "4000m", memory = "4Gi" }
}
```

## Backup and Recovery

### Manual Backup

```bash
# Export definitions (queues, exchanges, bindings)
kubectl exec -n messaging rabbitmq-0 -- \
  rabbitmqctl export_definitions /tmp/definitions.json

kubectl cp messaging/rabbitmq-0:/tmp/definitions.json ./backup.json
```

### Restore

```bash
kubectl cp ./backup.json messaging/rabbitmq-0:/tmp/definitions.json

kubectl exec -n messaging rabbitmq-0 -- \
  rabbitmqctl import_definitions /tmp/definitions.json
```

## References

- [Bitnami RabbitMQ Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq)
- [RabbitMQ Official Docs](https://www.rabbitmq.com/documentation.html)
- [RabbitMQ on Kubernetes](https://www.rabbitmq.com/kubernetes/operator/operator-overview.html)

---

**Module Version**: 1.0.0  
**Last Updated**: 2026-02-18  
**Maintained by**: OptimusFrame Team
