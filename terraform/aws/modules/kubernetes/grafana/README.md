# Módulo Terraform - Grafana no EKS

Este módulo instala e configura o Grafana no cluster EKS usando o Helm chart oficial do Grafana, com integração completa ao Amazon Cognito para autenticação SSO.

## Características

- **Autenticação SSO**: Integração com Amazon Cognito User Pool compartilhado com ArgoCD
- **Monitoramento Completo**: Configurado para monitorar métricas do EKS via Prometheus
- **Dashboards Pré-configurados**: Dashboards para monitoramento de cluster Kubernetes e Node Exporter
- **Persistência**: Armazenamento persistente para dados do Grafana
- **Ingress**: Configurado com NGINX Ingress Controller e certificado SSL
- **RBAC**: Controle de acesso baseado em grupos do Cognito

## Uso

```hcl
module "grafana" {
  source = "../modules/kubernetes/grafana/"

  # Configurações básicas
  namespace         = "monitoring"
  chart_version     = "8.5.2"
  domain_name       = "exemplo.com"
  grafana_subdomain = "grafana"
  environment       = "prod"

  # Configurações do Cognito (usando mesmo User Pool do ArgoCD)
  cognito_user_pool_id      = module.cognito.user_pool_id
  cognito_client_id         = module.cognito.grafana_client_id
  cognito_client_secret     = module.cognito.grafana_client_secret
  cognito_region            = var.aws_region
  cognito_client_issuer_url = module.cognito.grafana_issuer_url
  user_pool_name            = module.cognito.user_pool_name

  # Configurações de SSL
  certificate_arn = module.acm.certificate_arn

  # Configurações de grupos do Cognito
  admin_group_name        = "grafana"
  readonly_group_name     = "grafana-readonly"
  system_admin_group_name = "system-admins"

  # Configurações do Prometheus
  prometheus_url                = "http://prometheus-server.monitoring.svc.cluster.local"
  enable_prometheus_datasource  = true

  # Configurações de recursos
  storage_size  = "10Gi"
  storage_class = "gp2"

  grafana_resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }

  tags = var.tags
}
```

## Pré-requisitos

### 1. Cluster EKS Configurado

- EKS cluster funcionando
- NGINX Ingress Controller instalado
- Metrics Server instalado (via EKS add-on)
- Prometheus Node Exporter instalado (via EKS add-on)

### 2. Cognito User Pool

- User Pool do Cognito configurado
- Cliente OAuth configurado para Grafana
- Grupos de usuários criados:
  - `grafana` (administradores do Grafana)
  - `grafana-readonly` (usuários somente leitura)
  - `system-admins` (administradores de sistema)

### 3. DNS e Certificados

- Domínio configurado
- Certificado SSL via ACM

## Configuração de Autenticação

### Grupos do Cognito

O módulo mapeia grupos do Cognito para roles do Grafana:

- **`system-admins`**: Grafana Admin (acesso total)
- **`grafana`**: Grafana Admin (acesso total)
- **`grafana-readonly`**: Viewer (somente leitura)
- **Outros grupos**: Viewer (somente leitura)

### URLs de Callback

Configure as seguintes URLs no cliente OAuth do Cognito:

- **Callback URL**: `https://grafana.exemplo.com/login/generic_oauth`
- **Logout URL**: `https://grafana.exemplo.com`

## Monitoramento

### Datasources Pré-configurados

1. **Prometheus**: Fonte principal de métricas

   - URL: Configurável via `prometheus_url`
   - Acesso: Proxy
   - Intervalo: 5s

2. **Node Exporter**: Métricas específicas de nós
   - Mesmo Prometheus, configurado para Node Exporter

### Dashboards Incluídos

1. **Kubernetes Cluster Monitoring**

   - Visão geral do cluster
   - CPU e memória por nó
   - Contagem de pods e nós

2. **Node Exporter Full**
   - Métricas detalhadas dos nós
   - CPU, memória, disco, rede
   - I/O de disco e rede

### Service Monitor

Cria automaticamente um ServiceMonitor para que o Prometheus colete métricas do próprio Grafana.

## Volumes Persistentes

- **Tamanho padrão**: 10Gi
- **Storage Class padrão**: gp2 (AWS EBS)
- **Access Mode**: ReadWriteOnce

## Segurança

### Pod Security

- Executa como usuário não-root (472)
- Capabilities removidas
- Security Context restritivo

### Configurações de Segurança do Grafana

- Cookies seguros habilitados
- SameSite policy configurada
- Embedding desabilitado
- Analytics desabilitados

### RBAC

- Service Account dedicada
- RBAC habilitado
- Permissões mínimas necessárias

## Networking

### Ingress

- **Classe**: nginx
- **Protocolo**: HTTP (terminação SSL no Load Balancer)
- **Esquema**: internet-facing
- **Tipo de Target**: instance
- **Portas**: 80 (HTTP) e 443 (HTTPS)

### Service

- **Tipo**: ClusterIP
- **Porta**: 80
- **Target Port**: 3000

## Plugins Pré-instalados

- grafana-piechart-panel
- grafana-worldmap-panel
- grafana-clock-panel
- grafana-simple-json-datasource

## Variáveis

### Obrigatórias

| Nome                        | Descrição                  | Tipo   |
| --------------------------- | -------------------------- | ------ |
| `domain_name`               | Nome do domínio base       | string |
| `cognito_user_pool_id`      | ID do User Pool do Cognito | string |
| `cognito_client_id`         | ID do cliente OAuth        | string |
| `cognito_client_secret`     | Secret do cliente OAuth    | string |
| `cognito_region`            | Região do Cognito          | string |
| `cognito_client_issuer_url` | URL do issuer OIDC         | string |
| `user_pool_name`            | Nome base do User Pool     | string |

### Opcionais

| Nome                           | Descrição                          | Tipo   | Padrão                                                  |
| ------------------------------ | ---------------------------------- | ------ | ------------------------------------------------------- |
| `namespace`                    | Namespace do Kubernetes            | string | "monitoring"                                            |
| `chart_version`                | Versão do Helm chart               | string | "8.5.2"                                                 |
| `grafana_subdomain`            | Subdomínio do Grafana              | string | "grafana"                                               |
| `storage_size`                 | Tamanho do volume                  | string | "10Gi"                                                  |
| `storage_class`                | Classe de armazenamento            | string | "gp2"                                                   |
| `prometheus_url`               | URL do Prometheus                  | string | "http://prometheus-server.monitoring.svc.cluster.local" |
| `enable_prometheus_datasource` | Habilitar datasource do Prometheus | bool   | true                                                    |

## Outputs

| Nome                | Descrição                              |
| ------------------- | -------------------------------------- |
| `namespace`         | Namespace onde o Grafana foi instalado |
| `service_name`      | Nome do serviço do Grafana             |
| `url`               | URL de acesso ao Grafana               |
| `admin_user`        | Nome do usuário admin                  |
| `helm_release_name` | Nome do release do Helm                |

## Troubleshooting

### Problemas Comuns

1. **Erro de autenticação OAuth**

   - Verifique se as URLs de callback estão corretas no Cognito
   - Confirme se o client secret está correto

2. **Dashboards não aparecem**

   - Verifique se o Prometheus está acessível
   - Confirme a configuração do datasource

3. **Problemas de persistência**
   - Verifique se a storage class existe
   - Confirme se há volumes disponíveis

### Logs

```bash
# Logs do Grafana
kubectl logs -n monitoring deployment/grafana

# Status do Helm release
helm status grafana -n monitoring

# Verificar ingress
kubectl get ingress -n monitoring
```

## Integrações

### Com ArgoCD

- Compartilha o mesmo User Pool do Cognito
- Usuários podem usar as mesmas credenciais
- Grupos de acesso podem ser compartilhados

### Com Prometheus

- Datasource automático configurado
- ServiceMonitor para auto-discovery
- Dashboards pré-configurados para métricas do cluster

### Com EKS

- Monitora métricas do Metrics Server
- Coleta dados do Node Exporter
- Visualiza recursos do cluster
