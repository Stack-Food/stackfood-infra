# StackFood AWS Infrastructure

Este projeto contém a infraestrutura como código (IaC) para implantar a aplicação StackFood na AWS utilizando Terraform.

## Arquitetura

A infraestrutura AWS do StackFood consiste em:

- **VPC**: Rede isolada com subnets públicas e privadas distribuídas em várias zonas de disponibilidade
- **EKS**: Serviço gerenciado de Kubernetes para execução dos microserviços
- **RDS**: Banco de dados PostgreSQL gerenciado para armazenamento de dados
- **Lambda**: Funções serverless para processamento de eventos e API
- **API Gateway**: Gerenciamento de APIs para exposição dos serviços
- **S3**: Armazenamento de objetos para artefatos, backups e arquivos estáticos

## Estrutura do Projeto

```
terraform/
├── aws/
│   ├── env/             # Variáveis específicas por ambiente
│   │   ├── dev.tfvars   # Configurações do ambiente de desenvolvimento
│   │   └── prod.tfvars  # Configurações do ambiente de produção
│   ├── main/            # Configurações principais do Terraform
│   │   ├── locals.tf    # Variáveis locais
│   │   ├── main.tf      # Definição dos módulos
│   │   ├── outputs.tf   # Outputs do Terraform
│   │   ├── providers.tf # Configuração de providers
│   │   └── variables.tf # Definição das variáveis
│   └── modules/         # Módulos reutilizáveis
│       ├── eks/         # Módulo para EKS
│       ├── lambda/      # Módulo para Lambda
│       ├── rds/         # Módulo para RDS
│       └── vpc/         # Módulo para VPC
```

## Pré-requisitos

- Terraform >= 1.0.0
- AWS CLI configurado com acesso adequado
- Acesso ao S3 para armazenamento de estado do Terraform
- Acesso ao DynamoDB para bloqueio de estado do Terraform
- Kubectl para interagir com o cluster Kubernetes após o provisionamento

## Uso

## Ambientes

O projeto suporta múltiplos ambientes através de workspaces do Terraform:

- **dev**: Ambiente de desenvolvimento com recursos menores e menos redundância
- **prod**: Ambiente de produção com alta disponibilidade e recursos dimensionados adequadamente

## Segurança

A infraestrutura implementa as seguintes medidas de segurança:

- VPC com segregação apropriada de redes
- Acesso restrito por grupos de segurança
- Criptografia de dados em trânsito e em repouso
- Autenticação IAM para todos os serviços
- Endpoints privados para comunicação entre serviços
- Logs de auditoria habilitados para todos os serviços

## Boas Práticas

- Todas as senhas e segredos devem ser gerenciados pelo AWS Secrets Manager
- Use o script `terraform.sh` em vez de executar comandos Terraform diretamente
- Sempre faça um `plan` antes de aplicar mudanças
- Revise cuidadosamente as alterações antes de aplicá-las em produção
- Mantenha os módulos atualizados com as melhores práticas da AWS

## Monitoramento e Alarmes

A infraestrutura inclui configurações para:

- Logs centralizados no CloudWatch
- Métricas de performance e uso
- Alarmes para condições críticas
- Dashboards para visualização de métricas

## Contribuindo

1. Crie um branch para sua feature (`git checkout -b feature/nome-da-feature`)
2. Faça commit de suas mudanças (`git commit -m 'Adiciona nova feature'`)
3. Faça push para o branch (`git push origin feature/nome-da-feature`)
4. Abra um Pull Request

## Informações Adicionais

Para mais informações sobre os serviços AWS utilizados, consulte:

- [Amazon VPC](https://aws.amazon.com/vpc/)
- [Amazon EKS](https://aws.amazon.com/eks/)
- [Amazon RDS](https://aws.amazon.com/rds/)
- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
