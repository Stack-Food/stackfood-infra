# Observabilidade - Loki e Prometheus

Este diretório contém os módulos Terraform para a stack de observabilidade do cluster EKS, incluindo Grafana Loki para agregação de logs e Prometheus para coleta de métricas.

## Componentes

### 1. Grafana Loki

- **Chart**: `loki-stack` v2.10.2
- **Namespace**: `monitoring`
- **Componentes**:
  - **Loki**: Sistema de agregação de logs otimizado para Kubernetes
  - **Promtail**: Agent para coleta de logs dos pods

#### Configuração do Loki

- Retenção de logs: 7 dias (168h)
- Persistência: Desabilitada (compatível com AWS Academy)
- URL interna: `http://loki-stack.monitoring.svc.cluster.local:3100`

#### Coleta de Logs

O Promtail está configurado para coletar logs de:

- Todos os pods em namespaces de aplicação
- Exclui namespaces do sistema: `kube-system`, `kube-public`, `kube-node-lease`
- Labels automáticos:
  - `app`: Nome da aplicação
  - `namespace`: Namespace do pod
  - `pod`: Nome do pod
  - `container`: Nome do container
  - `node`: Nome do node
  - `pod_ip`: IP do pod

### 2. Prometheus

- **Chart**: `prometheus` v25.27.0
- **Namespace**: `monitoring`
- **Componentes**:
  - **Prometheus Server**: Servidor principal de coleta de métricas
  - **Node Exporter**: Exporta métricas dos nodes
  - **Kube State Metrics**: Exporta métricas do estado do Kubernetes

#### Configuração do Prometheus

- Retenção de métricas: 15 dias
- Persistência: Desabilitada (compatível com AWS Academy)
- URL interna: `http://prometheus-server.monitoring.svc.cluster.local`
- Intervalo de scrape: 15s
- Timeout de scrape: 10s

### 3. Integração com Grafana

Ambos os datasources são automaticamente configurados no Grafana:

#### Datasource Loki

- Nome: `Loki`
- Tipo: `loki`
- URL: `http://loki-stack.monitoring.svc.cluster.local:3100`
- Default: Sim (para logs)
- Máximo de linhas: 1000

#### Datasource Prometheus

- Nome: `Prometheus`
- Tipo: `prometheus`
- URL: `http://prometheus-server.monitoring.svc.cluster.local`
- Default: Não (Loki é default)
- Query timeout: 300s

## Uso

### Acessar o Grafana

1. Acesse: `https://grafana.<seu-dominio>`
2. Faça login com suas credenciais do Cognito
3. Os datasources Loki e Prometheus estarão pré-configurados

### Visualizar Logs (Loki)

No Grafana, vá para "Explore" e:

1. Selecione o datasource "Loki"
2. Use queries LogQL, por exemplo:

   ```logql
   # Logs de um namespace específico
   {namespace="default"}

   # Logs de uma aplicação específica
   {app="minha-app"}

   # Logs de um pod específico
   {pod="meu-pod-123"}

   # Filtrar por texto
   {namespace="default"} |= "error"

   # Combinar filtros
   {namespace="default", app="minha-app"} |= "error" != "debug"
   ```

### Visualizar Métricas (Prometheus)

No Grafana, vá para "Explore" e:

1. Selecione o datasource "Prometheus"
2. Use queries PromQL, por exemplo:

   ```promql
   # CPU usage dos containers
   rate(container_cpu_usage_seconds_total[5m])

   # Memory usage dos pods
   container_memory_usage_bytes

   # Network traffic
   rate(container_network_receive_bytes_total[5m])

   # Número de pods por namespace
   count(kube_pod_info) by (namespace)
   ```

## Estrutura dos Módulos

### Loki (`/loki`)

```
loki/
├── main.tf           # Helm release do Loki
├── variables.tf      # Variáveis de configuração
├── outputs.tf        # Outputs do módulo
├── providers.tf      # Provider requirements
└── loki.yml          # Valores do Helm chart
```

### Prometheus (`/prometheus`)

```
prometheus/
├── main.tf           # Helm release do Prometheus
├── variables.tf      # Variáveis de configuração
├── outputs.tf        # Outputs do módulo
├── providers.tf      # Provider requirements
└── prometheus.yml    # Valores do Helm chart
```

## Variáveis Disponíveis

### Módulo Loki

- `namespace`: Namespace do Kubernetes (default: `monitoring`)
- `chart_version`: Versão do chart (default: `2.10.2`)
- `retention_period`: Período de retenção em horas (default: `168h`)
- `enable_persistence`: Habilitar persistência (default: `false`)
- `storage_size`: Tamanho do armazenamento (default: `10Gi`)

### Módulo Prometheus

- `namespace`: Namespace do Kubernetes (default: `monitoring`)
- `chart_version`: Versão do chart (default: `25.27.0`)
- `retention_days`: Dias de retenção (default: `15`)
- `enable_persistence`: Habilitar persistência (default: `false`)
- `storage_size`: Tamanho do armazenamento (default: `20Gi`)
- `storage_class`: Storage class (default: `gp2`)

## Dependências

Estes módulos dependem de:

- EKS cluster configurado e operacional
- NGINX Ingress Controller instalado
- Grafana instalado (para visualização)

## Deployment

Os módulos são automaticamente deployados quando você executa:

```bash
cd terraform/aws/main
terraform init
terraform plan -var-file=../env/prod.tfvars
terraform apply -var-file=../env/prod.tfvars
```

A ordem de deployment é:

1. Prometheus
2. Loki
3. Grafana (com datasources pré-configurados)

## Troubleshooting

### Verificar status dos pods

```bash
kubectl get pods -n monitoring
```

### Verificar logs do Loki

```bash
kubectl logs -n monitoring -l app=loki --tail=100
```

### Verificar logs do Promtail

```bash
kubectl logs -n monitoring -l app=promtail --tail=100
```

### Verificar logs do Prometheus

```bash
kubectl logs -n monitoring -l app=prometheus --tail=100
```

### Testar conectividade do Loki

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://loki-stack.monitoring.svc.cluster.local:3100/ready
```

### Testar conectividade do Prometheus

```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://prometheus-server.monitoring.svc.cluster.local/-/healthy
```

## Limitações

### AWS Academy

- Persistência desabilitada (sem EBS CSI Driver)
- Logs e métricas são perdidos quando os pods são reiniciados
- Para produção real, habilite `enable_persistence = true` após configurar o EBS CSI Driver

### Recursos

- Prometheus: 200m CPU / 512Mi RAM (requests), 1000m CPU / 2Gi RAM (limits)
- Loki e Promtail: Sem limites definidos (usa defaults do chart)

## Próximos Passos

1. **Habilitar Persistência** (quando disponível EBS CSI Driver):

   ```hcl
   enable_persistence = true
   storage_class      = "gp3"
   ```

2. **Configurar Alertas** no Prometheus:

   - Adicionar regras de alerta
   - Configurar Alertmanager
   - Integrar com SNS ou outros canais

3. **Dashboards Customizados**:

   - Importar dashboards da comunidade
   - Criar dashboards específicos para suas aplicações
   - Configurar variáveis de template

4. **Long-term Storage** para Loki:
   - Configurar S3 backend para armazenamento de longo prazo
   - Habilitar compactação de logs

## Referências

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Datasources](https://grafana.com/docs/grafana/latest/datasources/)
- [LogQL Language](https://grafana.com/docs/loki/latest/logql/)
- [PromQL Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
