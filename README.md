# StackFood - Infraestrutura

## 📑 Índice

- Sobre o Projeto
- Arquitetura de Infraestrutura
- Estrutura de Diretórios
- Manifestos Kubernetes
  - Namespaces
  - Aplicações
  - Banco de Dados
- Metodologia GitOps
- Terraform AWS
  - Configuração e Implantação
  - IAM Roles
- Guia de Uso
  - Pré-requisitos
  - Configuração do Ambiente de Desenvolvimento
  - Iniciando o Ambiente de Testes
  - Realizando Requisições
  - Monitoramento e Logs
  - Limpeza do Ambiente
- Solução de Problemas
- Referências

## 🚀 Sobre o Projeto

StackFood é uma plataforma de gestão para food service que permite o gerenciamento de pedidos, clientes e pagamentos. Esta documentação descreve a infraestrutura Kubernetes utilizada para hospedar e executar os componentes da aplicação em ambientes de desenvolvimento e produção.

A infraestrutura foi projetada seguindo princípios de arquitetura moderna de aplicações, como microserviços, conteinerização e GitOps, visando escalabilidade, confiabilidade e facilidade de manutenção.

## 🏗 Arquitetura de Infraestrutura

A infraestrutura do StackFood consiste nos seguintes componentes principais:

- **API (stackfood-api)**: Serviço principal que expõe as funcionalidades da aplicação via endpoints RESTful
- **Banco de Dados PostgreSQL (stackfood-db)**: Armazenamento persistente de dados
- **Worker (stackfood-worker)**: Componente para processamento assíncrono de tarefas em background

A infraestrutura é implementada usando Kubernetes, permitindo:

- Implantação consistente entre ambientes (desenvolvimento e produção)
- Escalabilidade horizontal automática (HPA)
- Gerenciamento eficiente de configuração e segredos
- Resiliência e auto-recuperação

## 📂 Estrutura de Diretórios

A estrutura de diretórios deste repositório segue uma abordagem organizada por aplicação e ambiente:

```
stackfood-infra/
├── apps/                       # Aplicações e seus manifestos
│   ├── api/                    # API principal do StackFood
│   │   ├── base/               # Configurações base (compartilhadas)
│   │   ├── dev/                # Configurações específicas para desenvolvimento
│   │   └── prod/               # Configurações específicas para produção
│   ├── db/                     # Banco de dados PostgreSQL
│   │   ├── base/
│   │   ├── dev/
│   │   │   └── sql/            # Scripts SQL para inicialização do banco
│   │   └── prod/
│   ├── namespaces/             # Definição de namespaces
│   ├── shared/                 # Recursos compartilhados
│   │   └── secrets/            # Secrets comuns
│   └── webhook/                # Worker para processamento assíncrono
│       ├── base/
│       ├── dev/
│       └── prod/
├── scripts/                    # Scripts de automação e utilitários
│   ├── port-forward.sh         # Script para configurar port-forward
│   ├── test-local.sh           # Script para testar ambiente local
│   └── test-local-new.sh       # Versão otimizada do script de teste
└── terraform/                  # Infraestrutura como código (IaC) para AWS
    └── aws/                    # Recursos AWS usando Terraform
        ├── env/                # Configurações específicas de ambiente
        │   ├── dev.tfvars      # Variáveis para ambiente de desenvolvimento
        │   └── prod.tfvars     # Variáveis para ambiente de produção
        ├── main/               # Configuração principal do Terraform
        └── modules/            # Módulos Terraform reutilizáveis
            ├── eks/            # Módulo para Amazon EKS
            ├── lambda/         # Módulo para AWS Lambda
            ├── rds/            # Módulo para Amazon RDS
            └── vpc/            # Módulo para Amazon VPC
```

## 📝 Manifestos Kubernetes

### Namespaces

Os namespaces são utilizados para isolamento lógico entre ambientes:

```yaml
# apps/namespaces/dev-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: stackfood-dev
```

```yaml
# apps/namespaces/prod-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: stackfood
```

### Aplicações

As aplicações são organizadas usando Kustomize para gerenciar as configurações entre ambientes.

#### API (stackfood-api)

A API é implementada como um deployment Kubernetes:

**Base Configuration (apps/api/base/deployment.yaml)**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stackfood-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: stackfood-api
  template:
    spec:
      containers:
        - name: api
          image: ghcr.io/stack-food/stackfood-api:develop
          ports:
            - containerPort: 5039
              name: http
            - containerPort: 7189
              name: https
```

**Ambiente de Desenvolvimento (apps/api/dev/configmap.yaml)**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: stackfood-api-config
  namespace: stackfood-dev
data:
  ASPNETCORE_ENVIRONMENT: "Development"
  ASPNETCORE_URLS: "http://+:5039;https://+:7189"
  ConnectionStrings__DefaultConnection: "Host=stackfood-db.stackfood-dev.svc.cluster.local;Port=5432;Database=stackfood;Username=postgres;Password=password"
```

A API também inclui:

- **HPA (Horizontal Pod Autoscaler)** para escalabilidade automática
- **Service** para exposição interna
- **Probes** para health checks

### Banco de Dados

O banco de dados PostgreSQL é implementado como um StatefulSet para garantir persistência:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stackfood-db
spec:
  serviceName: stackfood-db
  replicas: 1
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:15.3-alpine
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
            - name: init-scripts
              mountPath: /docker-entrypoint-initdb.d
```

O banco também inclui:

- **Scripts de inicialização** para criar tabelas e estruturas
- **Persistent Volume Claims** para armazenamento durável
- **ConfigMaps** para configuração

## 🔄 Metodologia GitOps

Este projeto segue a metodologia GitOps para gerenciamento de infraestrutura, com os seguintes princípios:

1. **Código Declarativo**: Toda a infraestrutura é definida como código (IaC) em manifestos YAML.

2. **Versionamento no Git**: Todo o código de infraestrutura é versionado, permitindo rastreabilidade e auditoria.

3. **Segregação de Ambientes**: Desenvolvimento e produção são separados em diretórios distintos.

4. **Kustomize para Camadas de Configuração**: Usamos Kustomize para gerenciar as diferenças entre ambientes.

## ☁️ Terraform AWS

A infraestrutura na AWS é provisionada usando Terraform, que permite definir e gerenciar recursos como código.

### Configuração e Implantação

Para implantar a infraestrutura na AWS:

1. Configure as credenciais AWS (utilizando o AWS CLI ou variáveis de ambiente)
2. Navegue até o diretório `terraform/aws`
3. Inicialize o Terraform:
   ```bash
   terraform init
   ```
4. Aplique a configuração para o ambiente desejado:

   ```bash
   # Para ambiente de desenvolvimento
   terraform apply -var-file=env/dev.tfvars

   # Para ambiente de produção
   terraform apply -var-file=env/prod.tfvars
   ```

### IAM Roles

Este projeto utiliza IAM roles existentes na AWS em vez de criar novos roles, seguindo as práticas recomendadas de segurança e permissões mínimas necessárias:

1. **Lambda Functions**: Utilizam o role existente `LabRole` para permissões de execução
2. **EKS Cluster**: Utiliza o role existente `LabEksClusterRole` para o plano de controle
3. **EKS Nodes**: Utilizam o role existente `LabEksNodeRole` para os nós workers

Essa abordagem simplifica a gestão de permissões e garante conformidade com políticas de segurança organizacionais.

## 💻 Guia de Uso

### Pré-requisitos

Para utilizar esta infraestrutura, você precisa ter instalado:

- **Kubernetes**: De preferencia o minikube
- **kubectl**: CLI para comunicar com a API do K8S
- **Docker**: Para utlizar o container runtime no cluster K8S
- **git**: Para clonar o repositório
- **bash**: Para executar os scripts de automação
- **Terraform**: Para provisionar recursos na AWS (versão 1.0+)
- **AWS CLI**: Para autenticação e interação com a AWS

### Configuração do Ambiente de Desenvolvimento

1. **Clone o repositório**:

```bash
git clone https://github.com/stack-food/stackfood-infra.git
cd stackfood-infra
```

2.  **Certifique-se que os scripts têm permissão de execução**:

```bash
chmod +x scripts/*.sh
```

### Iniciando o Ambiente de Testes

Para iniciar o ambiente completo, execute o script e adicione o parameto a frente para executar o ambiente desejado

**Ambientes disponíveis:**

- `dev`: Configura ambiente de desenvolvimento
- `prod`: Configura ambiente de produção

#### Exemplos

```bash
# Iniciar ambiente de desenvolvimento
./test-local.sh dev

# Iniciar ambiente de produção
./test-local.sh prod
```

Este script realiza as seguintes operações:

- Verifica se o Minikube está em execução
- Cria o namespace de desenvolvimento
- Aplica os manifestos do banco de dados e da API
- Configura port-forward para acesso aos serviços
- Verifica a conectividade com a API

### Realizando Requisições

Após a inicialização, você pode acessar:

- **Swagger UI**: [http://localhost:8080/swagger/index.html](http://localhost:8080/swagger/index.html)
- **API HTTPS**: [https://localhost:8443](https://localhost:8443)

Exemplo de requisição para criar um cliente:

```bash
curl -X 'POST' \
  'http://localhost:8080/api/customers' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
"name": "Cliente PAGO",
"email": "teste@gmail.com",
"cpf": "42226461647"
}'
```

### Monitoramento e Logs

Para verificar logs da aplicação:

```bash
# Logs da API
kubectl logs -l app=stackfood-api -n stackfood-dev --tail=50

# Logs do banco de dados
kubectl logs -l app=stackfood-db -n stackfood-dev --tail=50
```

### Limpeza do Ambiente

Quando terminar os testes, execute:

```bash
# Remover namespace e recursos associados
kubectl delete namespace stackfood-dev

# Encerrar processos de port-forward
pkill -f "kubectl port-forward"
```

## ⚠️ Solução de Problemas

### Problema: Erro de conexão com o banco de dados

Se encontrar erros de autenticação no banco de dados:

```
password authentication failed for user "postgres"
```

Verifique:

1. Se a senha no Secret corresponde à usada na string de conexão
2. Se o Secret foi aplicado corretamente no namespace
3. Execute `kubectl describe pod -l app=stackfood-db -n stackfood-dev` para verificar eventos

### Problema: Tabelas não são criadas no banco de dados

Se as tabelas não forem criadas automaticamente:

```
relation "customer" does not exist
```

Verifique:

1. Se o ConfigMap `stackfood-db-init-scripts` foi criado corretamente
2. Se o script SQL está sendo montado no path correto
3. Certifique-se que está usando `disableNameSuffixHash: true` no configMapGenerator
4. Tente recriar o StatefulSet e o PVC para forçar uma reinicialização limpa

## 📚 Referências

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Postgres on Kubernetes](https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/)

---
