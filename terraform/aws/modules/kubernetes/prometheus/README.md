# Prometheus Module

Terraform module para deploy do Prometheus no cluster EKS usando Helm.

## Descrição

Este módulo instala o Prometheus stack, que inclui:

- **Prometheus Server**: Servidor principal de coleta e armazenamento de métricas
- **Node Exporter**: DaemonSet que exporta métricas de hardware e OS dos nodes
- **Kube State Metrics**: Exporta métricas sobre o estado dos objetos Kubernetes

## Recursos Criados

- Helm Release do Prometheus no namespace `monitoring`
- Prometheus Server (deployment)
- Node Exporter (DaemonSet)
- Kube State Metrics (deployment)
- Services para expor os componentes

## Uso

```hcl
module "prometheus" {
  source = "../modules/kubernetes/prometheus/"

  namespace     = "monitoring"
  chart_version = "25.27.0"

  retention_days     = 15
  enable_persistence = false
  storage_size       = "20Gi"
  storage_class      = "gp2"
}
```

## Inputs

| Nome               | Descrição                     | Tipo     | Default        | Requerido |
| ------------------ | ----------------------------- | -------- | -------------- | --------- |
| namespace          | Namespace do Kubernetes       | `string` | `"monitoring"` | não       |
| chart_version      | Versão do Helm chart          | `string` | `"25.27.0"`    | não       |
| retention_days     | Dias de retenção das métricas | `number` | `15`           | não       |
| enable_persistence | Habilitar volume persistente  | `bool`   | `false`        | não       |
| storage_size       | Tamanho do volume             | `string` | `"20Gi"`       | não       |
| storage_class      | Storage class do volume       | `string` | `"gp2"`        | não       |

## Outputs

| Nome           | Descrição                                |
| -------------- | ---------------------------------------- |
| prometheus_url | URL interna do serviço Prometheus        |
| namespace      | Namespace onde Prometheus está instalado |
| release_name   | Nome do Helm release                     |
| chart_version  | Versão do chart instalado                |

## Configuração de Scraping

### Intervalos

- **Scrape interval**: 15s
- **Scrape timeout**: 10s
- **Evaluation interval**: 15s

### Targets Automáticos

Prometheus descobre e monitora automaticamente:

- Todos os pods com anotações de Prometheus
- Services do Kubernetes
- Nodes do cluster (via Node Exporter)
- Estado do cluster (via Kube State Metrics)

### Habilitar Scraping em Pods

Adicione estas anotações aos seus pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

## Queries PromQL Úteis

```promql
# CPU usage por container
rate(container_cpu_usage_seconds_total[5m])

# Memory usage por pod
container_memory_usage_bytes{pod="meu-pod"}

# Network traffic
rate(container_network_receive_bytes_total[5m])

# Pods por namespace
count(kube_pod_info) by (namespace)

# Pod restarts
kube_pod_container_status_restarts_total

# CPU request vs usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod) /
sum(kube_pod_container_resource_requests{resource="cpu"}) by (pod)

# Memory request vs usage
sum(container_memory_usage_bytes) by (pod) /
sum(kube_pod_container_resource_requests{resource="memory"}) by (pod)

# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)
```

## Métricas Disponíveis

### Container Metrics

- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_memory_working_set_bytes`
- `container_network_receive_bytes_total`
- `container_network_transmit_bytes_total`

### Kubernetes State Metrics

- `kube_pod_info`
- `kube_pod_status_phase`
- `kube_pod_container_status_restarts_total`
- `kube_deployment_status_replicas`
- `kube_node_status_condition`

### Node Metrics

- `node_cpu_seconds_total`
- `node_memory_MemTotal_bytes`
- `node_memory_MemAvailable_bytes`
- `node_filesystem_size_bytes`
- `node_filesystem_avail_bytes`
- `node_network_receive_bytes_total`
- `node_network_transmit_bytes_total`

## Verificação

### Verificar instalação

```bash
kubectl get pods -n monitoring -l app=prometheus
kubectl get pods -n monitoring -l app=node-exporter
kubectl get pods -n monitoring -l app=kube-state-metrics
```

### Verificar logs

```bash
kubectl logs -n monitoring -l app=prometheus --tail=50
```

### Acessar UI do Prometheus (port-forward)

```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Acesse http://localhost:9090
```

### Testar API

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://prometheus-server.monitoring.svc.cluster.local/-/healthy
```

### Query via API

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -G -s "http://prometheus-server.monitoring.svc.cluster.local/api/v1/query" \
  --data-urlencode 'query=up'
```

## Recursos

### Prometheus Server

- **Requests**: 200m CPU, 512Mi RAM
- **Limits**: 1000m CPU, 2Gi RAM

### Componentes Desabilitados

- Alertmanager (pode ser habilitado conforme necessário)
- Pushgateway (não recomendado para Kubernetes)

## Notas

- Por padrão, a persistência está **desabilitada** para compatibilidade com AWS Academy
- Métricas são armazenadas em volumes efêmeros e serão perdidas quando o pod reiniciar
- Para produção, habilite `enable_persistence = true` após configurar o EBS CSI Driver
- Retenção padrão: 15 dias

## Configurar Alertas

Para adicionar regras de alerta, você pode estender a configuração do Helm:

```hcl
module "prometheus" {
  # ... outras configurações ...

  alert_rules = {
    groups = [
      {
        name = "instance"
        rules = [
          {
            alert = "InstanceDown"
            expr  = "up == 0"
            for   = "5m"
            labels = {
              severity = "critical"
            }
            annotations = {
              summary     = "Instance {{ $labels.instance }} down"
              description = "{{ $labels.instance }} has been down for more than 5 minutes."
            }
          }
        ]
      }
    ]
  }
}
```

## Dependências

- Cluster EKS operacional
- Helm provider configurado
- Namespace `monitoring` (criado automaticamente)

## Referências

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Prometheus Helm Chart](https://prometheus-community.github.io/helm-charts)
- [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
- [Node Exporter](https://github.com/prometheus/node_exporter)
