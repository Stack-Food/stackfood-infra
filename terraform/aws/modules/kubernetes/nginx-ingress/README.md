# NGINX Ingress Module

## Overview

This module deploys NGINX Ingress Controller on Kubernetes, providing HTTP/HTTPS load balancing, SSL termination, and traffic routing for applications within the EKS cluster.

## Resources Created

- NGINX Ingress Controller Helm deployment
- Network Load Balancer for external traffic
- Service accounts and RBAC configurations
- SSL certificate management
- Ingress classes and admission webhooks
- Metrics and monitoring endpoints

## Architecture

```
NGINX Ingress Controller
├── External Load Balancer (NLB)
│   ├── Port 80 (HTTP)
│   ├── Port 443 (HTTPS)
│   └── Health Checks
├── NGINX Controller Pod
│   ├── Configuration Reload
│   ├── SSL Termination
│   ├── Request Routing
│   └── Rate Limiting
├── Default Backend
│   ├── 404 Responses
│   └── Health Checks
└── Monitoring
    ├── Prometheus Metrics
    ├── Access Logs
    └── Error Logs
```

## Inputs

| Variable                   | Type        | Description             | Default         |
| -------------------------- | ----------- | ----------------------- | --------------- |
| `nginx_ingress_name`       | string      | Ingress controller name | "ingress-nginx" |
| `nginx_ingress_repository` | string      | Helm repository URL     | required        |
| `nginx_ingress_chart`      | string      | Helm chart name         | "ingress-nginx" |
| `nginx_ingress_version`    | string      | Chart version           | "4.10.0"        |
| `nginx_ingress_namespace`  | string      | Kubernetes namespace    | "ingress-nginx" |
| `environment`              | string      | Environment name        | required        |
| `tags`                     | map(string) | Resource tags           | {}              |

## Service Configuration

```yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
```

## Outputs

| Output                    | Description                     |
| ------------------------- | ------------------------------- |
| `ingress_controller_name` | Controller name                 |
| `ingress_namespace`       | Kubernetes namespace            |
| `load_balancer_hostname`  | External load balancer hostname |
| `ingress_class_name`      | Ingress class for routing       |

## Example Usage

```hcl
module "nginx_ingress" {
  source = "../modules/kubernetes/nginx-ingress/"

  nginx_ingress_name       = "ingress-nginx"
  nginx_ingress_repository = "https://kubernetes.github.io/ingress-nginx"
  nginx_ingress_chart      = "ingress-nginx"
  nginx_ingress_version    = "4.10.0"
  nginx_ingress_namespace  = "ingress-nginx"
  environment              = "prod"

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- HTTP/HTTPS load balancing
- SSL/TLS termination with certificate management
- Path-based and host-based routing
- Rate limiting and request throttling
- WebSocket and gRPC support
- Custom error pages and redirects

## Load Balancer Integration

### AWS Network Load Balancer (NLB)

- Layer 4 load balancing for high performance
- Cross-zone load balancing for availability
- Health checks with automatic failover
- Static IP addresses for DNS configuration
- Support for millions of requests per second

## Security

- WAF integration capabilities
- IP whitelist and blacklist
- Request size and rate limiting
- Header injection and removal
- Authentication and authorization hooks

## Monitoring

- Prometheus metrics endpoint
- Access and error logs
- Request duration and rate metrics
- Health check monitoring
- Custom dashboards with Grafana

Se você encontrar o erro "context deadline exceeded" ao aplicar este módulo, aqui estão algumas soluções:

### Solução 1: Desativar atomic e wait

Edite o arquivo `main.tf` deste módulo e altere as seguintes configurações:

```hcl
atomic = false
wait  = false
```

Isso impedirá que o Terraform espere pela conclusão da instalação, o que pode evitar o timeout.

### Solução 2: Usar o script manual

Se a Solução 1 não funcionar, você pode usar o script manual fornecido:

```bash
chmod +x /home/luizf/fiap/stackfood-infra/scripts/manual-nginx-ingress-install.sh
/home/luizf/fiap/stackfood-infra/scripts/manual-nginx-ingress-install.sh
```

Depois, comente o módulo nginx-ingress no arquivo `main.tf` principal para evitar conflitos.

### Solução 3: Verificar conectividade

Certifique-se de que:

- Você tem acesso ao cluster EKS (`kubectl cluster-info`)
- O cluster está saudável (`kubectl get nodes`)
- As credenciais estão corretamente configuradas (`aws eks update-kubeconfig`)
