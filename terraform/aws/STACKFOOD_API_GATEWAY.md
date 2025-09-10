# StackFood API Gateway Configuration

Esta documentação descreve a configuração do API Gateway baseada na especificação Swagger da API StackFood.

## Rotas Implementadas

Baseado no arquivo `swagger.json`, as seguintes rotas foram configuradas:

### 1. Customer Endpoints

#### POST /api/customers

- **Descrição**: Cria um novo cliente no banco de dados
- **Autorização**: Nenhuma (para POC)
- **Body**: CreateCustomerRequest (name, email, cpf)
- **Response**: 200 Success

#### GET /api/customers/{cpf}

- **Descrição**: Busca um cliente por CPF
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: cpf (path parameter)
- **Response**: 200 Success

### 2. Order Endpoints

#### GET /api/order

- **Descrição**: Lista todos os pedidos, opcionalmente filtrados por status
- **Autorização**: Nenhuma (para POC)
- **Query Parameters**: status (opcional, OrderStatus enum)
- **Response**: 200 Success

#### POST /api/order

- **Descrição**: Cria um novo pedido
- **Autorização**: Nenhuma (para POC)
- **Body**: CreateOrderRequest (customerId, products array)
- **Response**: 200 Success

#### GET /api/order/{id}

- **Descrição**: Busca detalhes de um pedido específico
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: id (path parameter, UUID)
- **Response**: 200 Success

#### PUT /api/order/{id}/payment

- **Descrição**: Gera pagamento para um pedido específico
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: id (path parameter, UUID)
- **Body**: GeneratePaymentRequest (type)
- **Response**: 200 Success

#### PUT /api/order/{id}/change-status

- **Descrição**: Altera o status de um pedido
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: id (path parameter, UUID)
- **Body**: ChangeStatusRequest (status)
- **Response**: 200 Success

### 3. Product Endpoints

#### GET /api/product/all

- **Descrição**: Lista todos os produtos do catálogo
- **Autorização**: Nenhuma (para POC)
- **Query Parameters**: category (opcional, ProductCategory enum)
- **Response**: 200 Success

#### GET /api/product/{id}

- **Descrição**: Busca um produto por ID
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: id (path parameter, UUID)
- **Response**: 200 Success

#### DELETE /api/product/{id}

- **Descrição**: Deleta um produto por ID
- **Autorização**: Nenhuma (para POC)
- **Parâmetros**: id (path parameter, UUID)
- **Response**: 200 Success

#### POST /api/product

- **Descrição**: Cria um novo produto no catálogo
- **Autorização**: Nenhuma (para POC)
- **Body**: CreateProductRequest (name, desc, price, img, category)
- **Response**: 200 Success

#### PUT /api/product

- **Descrição**: Atualiza informações de um produto existente
- **Autorização**: Nenhuma (para POC)
- **Body**: UpdateProductRequest (id, name, desc, price, img, category)
- **Response**: 200 Success

## Estrutura de Recursos do API Gateway

```
/api
├── /customers
│   └── /{cpf}
├── /order
│   └── /{id}
│       ├── /payment
│       └── /change-status
└── /product
    ├── /all
    └── /{id}
```

## Configuração Terraform

### Arquivo poc.tfvars (POC - Proof of Concept)

Para ambiente de POC, foi criada uma configuração simplificada com:

- **Integrações Mock**: Respostas mock para testar a estrutura sem Lambda
- **Sem Autenticação**: Todos os endpoints configurados como "NONE" para facilitar testes
- **CORS Aberto**: Configurado para aceitar qualquer origem (\*)
- **Sem Cache**: Desabilitado para simplificar
- **Sem API Keys**: Não necessário para POC

### Arquivo prod.tfvars (Produção)

Para ambiente de produção, a configuração inclui:

- **Integrações Lambda**: Todas as rotas apontam para função Lambda
- **CORS Restritivo**: Apenas domínios específicos permitidos
- **Monitoramento**: CloudWatch logs e métricas habilitados
- **Autenticação**: Preparado para autenticação (atualmente NONE para simplicidade)

## Schema Types (baseado no Swagger)

### Enums

- **OrderStatus**: 1, 2, 3, 4, 5 (inteiros)
- **PaymentType**: 1 (inteiro)
- **ProductCategory**: 1, 2, 3, 4 (inteiros)

### Request Types

- **CreateCustomerRequest**: name, email, cpf
- **CreateOrderRequest**: customerId, products array
- **CreateOrderProductRequest**: productId, quantity
- **CreateProductRequest**: name, desc, price, img, category
- **UpdateProductRequest**: id, name, desc, price, img, category
- **GeneratePaymentRequest**: type
- **ChangeStatusRequest**: status

## Exemplos de URLs

Após o deploy, as URLs seguirão o padrão:

```
https://{api-id}.execute-api.us-west-2.amazonaws.com/poc/api/customers
https://{api-id}.execute-api.us-west-2.amazonaws.com/poc/api/order
https://{api-id}.execute-api.us-west-2.amazonaws.com/poc/api/product/all
```

## Testes com curl

### Criar Cliente

```bash
curl -X POST https://API_URL/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@email.com",
    "cpf": "12345678901"
  }'
```

### Listar Produtos

```bash
curl -X GET https://API_URL/api/product/all
```

### Criar Pedido

```bash
curl -X POST https://API_URL/api/order \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "123e4567-e89b-12d3-a456-426614174000",
    "products": [
      {
        "productId": "456e7890-e89b-12d3-a456-426614174000",
        "quantity": 2
      }
    ]
  }'
```

## Próximos Passos

1. **Deploy POC**: Usar `poc.tfvars` para deploy inicial com integrações mock
2. **Desenvolvimento Lambda**: Criar função Lambda que processa todas as rotas
3. **Atualizar Integrações**: Substituir integrações mock por Lambda
4. **Testes de Integração**: Validar funcionamento end-to-end
5. **Autenticação**: Implementar autenticação conforme necessário
6. **Monitoramento**: Configurar dashboards e alertas

## Observações para POC

- Todas as rotas estão configuradas mas apontam para integrações mock
- Para testar com Lambda real, substitua as integrações mock por AWS_PROXY
- As estruturas de request/response estão preparadas conforme o Swagger
- CORS está configurado de forma permissiva para facilitar testes
- Sem throttling ou rate limiting para não limitar testes iniciais
