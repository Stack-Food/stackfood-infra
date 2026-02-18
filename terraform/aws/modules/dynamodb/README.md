# DynamoDB Module

Este módulo cria e gerencia tabelas DynamoDB com suporte completo para índices secundários, autoscaling, streams, e muito mais.

## Funcionalidades

- ✅ Criação de tabelas DynamoDB
- ✅ Suporte a índices secundários globais (GSI) e locais (LSI)
- ✅ DynamoDB Streams
- ✅ Time-to-Live (TTL)
- ✅ Point-in-time Recovery (PITR)
- ✅ Server-side Encryption (SSE) com KMS
- ✅ Autoscaling automático de capacidade (modo PROVISIONED)
- ✅ CloudWatch Alarms para throttling
- ✅ Suporte a tabelas globais (replicas)
- ✅ Table Classes (STANDARD e STANDARD_INFREQUENT_ACCESS)

## Uso Básico

### Tabela Simples (Pay-per-request)

```hcl
module "orders_table" {
  source = "../modules/dynamodb/"

  table_name  = "OptimusFrame-orders"
  hash_key    = "order_id"
  environment = "prod"

  attributes = [
    {
      name = "order_id"
      type = "S"
    }
  ]

  tags = {
    Project = "OptimusFrame"
  }
}
```

### Tabela com Range Key e GSI

```hcl
module "orders_table" {
  source = "../modules/dynamodb/"

  table_name  = "OptimusFrame-orders"
  hash_key    = "customer_id"
  range_key   = "order_date"
  environment = "prod"

  attributes = [
    {
      name = "customer_id"
      type = "S"
    },
    {
      name = "order_date"
      type = "S"
    },
    {
      name = "status"
      type = "S"
    }
  ]

  # Índice secundário global para buscar por status
  global_secondary_indexes = [
    {
      name            = "status-index"
      hash_key        = "status"
      range_key       = "order_date"
      projection_type = "ALL"
    }
  ]

  # Habilitar streams para processar eventos
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # TTL para expiração automática
  ttl_enabled        = true
  ttl_attribute_name = "expiration_time"

  tags = {
    Project = "OptimusFrame"
  }
}
```

### Tabela com Capacidade Provisionada e Autoscaling

```hcl
module "products_table" {
  source = "../modules/dynamodb/"

  table_name   = "OptimusFrame-products"
  hash_key     = "product_id"
  billing_mode = "PROVISIONED"
  environment  = "prod"

  # Capacidades iniciais
  read_capacity  = 5
  write_capacity = 5

  attributes = [
    {
      name = "product_id"
      type = "S"
    }
  ]

  # Habilitar autoscaling
  autoscaling_enabled           = true
  autoscaling_read_max_capacity = 100
  autoscaling_write_max_capacity = 100
  autoscaling_read_target_value  = 70
  autoscaling_write_target_value = 70

  # Criar alarmes de throttling
  create_alarms                   = true
  alarm_read_throttle_threshold  = 10
  alarm_write_throttle_threshold = 10

  tags = {
    Project = "OptimusFrame"
  }
}
```

### Tabela Global (Multi-região)

```hcl
module "global_table" {
  source = "../modules/dynamodb/"

  table_name  = "OptimusFrame-global"
  hash_key    = "id"
  environment = "prod"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  # Criar réplicas em outras regiões
  replica_regions = [
    {
      region_name            = "us-west-2"
      point_in_time_recovery = true
    },
    {
      region_name            = "eu-west-1"
      point_in_time_recovery = true
    }
  ]

  tags = {
    Project = "OptimusFrame"
  }
}
```

## Variáveis

### Obrigatórias

| Nome          | Descrição                     | Tipo           | Default |
| ------------- | ----------------------------- | -------------- | ------- |
| `table_name`  | Nome da tabela DynamoDB       | `string`       | -       |
| `hash_key`    | Chave de partição             | `string`       | -       |
| `attributes`  | Lista de atributos da tabela  | `list(object)` | -       |
| `environment` | Ambiente (dev, staging, prod) | `string`       | -       |

### Opcionais

| Nome                             | Descrição                                         | Tipo           | Default              |
| -------------------------------- | ------------------------------------------------- | -------------- | -------------------- |
| `range_key`                      | Chave de ordenação                                | `string`       | `null`               |
| `billing_mode`                   | Modo de cobrança (PROVISIONED ou PAY_PER_REQUEST) | `string`       | `PAY_PER_REQUEST`    |
| `read_capacity`                  | Unidades de leitura (PROVISIONED)                 | `number`       | `5`                  |
| `write_capacity`                 | Unidades de escrita (PROVISIONED)                 | `number`       | `5`                  |
| `stream_enabled`                 | Habilitar DynamoDB Streams                        | `bool`         | `false`              |
| `stream_view_type`               | Tipo de view do stream                            | `string`       | `NEW_AND_OLD_IMAGES` |
| `ttl_enabled`                    | Habilitar TTL                                     | `bool`         | `false`              |
| `point_in_time_recovery_enabled` | Habilitar PITR                                    | `bool`         | `true`               |
| `encryption_enabled`             | Habilitar criptografia                            | `bool`         | `true`               |
| `table_class`                    | Classe da tabela                                  | `string`       | `STANDARD`           |
| `global_secondary_indexes`       | Lista de GSIs                                     | `list(object)` | `[]`                 |
| `local_secondary_indexes`        | Lista de LSIs                                     | `list(object)` | `[]`                 |
| `autoscaling_enabled`            | Habilitar autoscaling                             | `bool`         | `false`              |

## Outputs

| Nome               | Descrição                     |
| ------------------ | ----------------------------- |
| `table_id`         | ID da tabela                  |
| `table_name`       | Nome da tabela                |
| `table_arn`        | ARN da tabela                 |
| `table_stream_arn` | ARN do stream (se habilitado) |
| `hash_key`         | Chave de partição             |
| `range_key`        | Chave de ordenação            |
| `billing_mode`     | Modo de cobrança              |

## Tipos de Atributos

- `S` - String
- `N` - Number
- `B` - Binary

## Projection Types

- `ALL` - Todos os atributos
- `KEYS_ONLY` - Apenas chaves
- `INCLUDE` - Chaves + atributos especificados

## Stream View Types

- `KEYS_ONLY` - Apenas as chaves
- `NEW_IMAGE` - Apenas o novo item
- `OLD_IMAGE` - Apenas o item antigo
- `NEW_AND_OLD_IMAGES` - Ambos os itens

## Exemplos de Uso no Main

```hcl
module "orders_dynamodb" {
  source = "../modules/dynamodb/"

  table_name  = "OptimusFrame-orders-${var.environment}"
  hash_key    = "order_id"
  range_key   = "created_at"
  environment = var.environment

  attributes = [
    {
      name = "order_id"
      type = "S"
    },
    {
      name = "created_at"
      type = "N"
    },
    {
      name = "customer_id"
      type = "S"
    },
    {
      name = "status"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "customer-index"
      hash_key        = "customer_id"
      range_key       = "created_at"
      projection_type = "ALL"
    },
    {
      name            = "status-index"
      hash_key        = "status"
      range_key       = "created_at"
      projection_type = "KEYS_ONLY"
    }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  ttl_enabled        = true
  ttl_attribute_name = "ttl"

  point_in_time_recovery_enabled = true
  encryption_enabled             = true

  tags = var.tags
}
```

## Notas Importantes

- **Pay-per-request** é recomendado para workloads variáveis e desenvolvimento
- **PROVISIONED** com autoscaling é melhor para workloads previsíveis em produção
- **Streams** são úteis para integração com Lambda, processamento de eventos, etc.
- **TTL** não tem custo adicional e é útil para limpeza automática de dados
- **PITR** permite recuperação de até 35 dias no passado
- **LSIs** só podem ser criados na criação da tabela (não podem ser adicionados depois)
- **GSIs** podem ser adicionados/removidos a qualquer momento
