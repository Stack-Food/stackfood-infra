# StackFood Cognito - Autenticação por CPF

Este documento descreve a configuração do AWS Cognito para autenticação de clientes StackFood **apenas com CPF**, sem necessidade de senha, seguindo os requisitos específicos do projeto.

## 📋 Visão Geral dos Requisitos

### Fluxo de Autenticação Simplificado

- ✅ **Entrada**: Apenas CPF do cliente
- ✅ **Sem Senha**: Cliente não insere qualquer tipo de senha
- ✅ **JWT**: Retorna token JWT para acesso à API
- ✅ **API Gateway**: Integração completa com API Gateway
- ✅ **Lambda**: Autenticação via função serverless

## 🏗️ Arquitetura de Autenticação por CPF

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cliente       │    │   API Gateway   │    │ Lambda Auth     │
│   (CPF Input)   │    │   (JWT Verify)  │    │ (CPF Lookup)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ POST /auth/cpf        │                       │
         │ { "cpf": "12345..." } │                       │
         ├──────────────────────►│                       │
         │                       │ Invoke Lambda         │
         │                       ├──────────────────────►│
         │                       │                       │
         │                       │ ◄────────────────────┤
         │                       │ JWT Token             │
         │ ◄────────────────────┤                       │
         │ { "token": "eyJ..." } │                       │
         │                       │                       │
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ Cognito Custom  │    │ User Pool       │    │ CPF Database    │
    │ Auth Challenge  │    │ (JWT Issuer)    │    │ (Validation)    │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔐 Configuração de Segurança Específica

### Autenticação Customizada (Sem Senha)

- **Username**: CPF como identificador único
- **Alias**: `preferred_username` para CPF
- **Auth Flow**: `ALLOW_CUSTOM_AUTH` apenas
- **Verificação**: Via Lambda triggers

### Lambda Triggers para CPF Auth

```javascript
// Define Auth Challenge - Define que não precisa de senha
exports.defineAuthChallenge = async (event) => {
  if (event.request.session.length === 0) {
    // Primeiro desafio: verificar CPF
    event.response.challengeName = "CUSTOM_CHALLENGE";
    event.response.issueTokens = false;
  } else if (
    event.request.session.length === 1 &&
    event.request.session[0].challengeResult === true
  ) {
    // CPF válido, emitir tokens
    event.response.issueTokens = true;
  } else {
    // CPF inválido
    event.response.issueTokens = false;
  }
  return event;
};

// Create Auth Challenge - Cria desafio personalizado
exports.createAuthChallenge = async (event) => {
  if (event.request.challengeName === "CUSTOM_CHALLENGE") {
    // Configurar desafio de validação de CPF
    event.response.publicChallengeParameters = {
      trigger: "true",
    };
    event.response.privateChallengeParameters = {
      answer: event.request.userAttributes["custom:cpf"],
    };
  }
  return event;
};

// Verify Auth Challenge - Verifica se CPF é válido
exports.verifyAuthChallenge = async (event) => {
  const expectedAnswer = event.request.privateChallengeParameters.answer;
  const providedAnswer = event.request.challengeAnswer;

  // Validar CPF e verificar se existe no sistema
  const isValidCPF = validateCPF(providedAnswer);
  const customerExists = await checkCustomerByCPF(providedAnswer);

  event.response.answerCorrect =
    isValidCPF && customerExists && providedAnswer === expectedAnswer;
  return event;
};
```

## 👥 Clientes Configurados

### 1. CPF Auth App (stackfood-cpf-auth)

```bash
Tipo: Single Page Application para autenticação por CPF
Secret: Não requerido
OAuth Flows: implicit
Auth Flows: ALLOW_CUSTOM_AUTH, ALLOW_REFRESH_TOKEN_AUTH
Scopes: openid, profile, aws.cognito.signin.user.admin
Callback URLs: localhost:3000/callback, stackfood-prod.com/callback
```

### 2. API Backend (stackfood-api-backend)

```bash
Tipo: Serviço Backend para gerenciamento de usuários
Secret: Requerido
OAuth Flows: client_credentials
Auth Flows: ALLOW_ADMIN_USER_PASSWORD_AUTH, ALLOW_CUSTOM_AUTH, ALLOW_REFRESH_TOKEN_AUTH
Scopes: aws.cognito.signin.user.admin
Uso: Criação e gestão de usuários via CPF
```

## 🎯 Fluxo de Autenticação Completo

### 1. Registro de Cliente (Via Lambda Backend)

```javascript
// Lambda para registrar cliente com CPF
const AWS = require("aws-sdk");
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.registerCustomer = async (event) => {
  const { cpf, name, familyName, customerType } = JSON.parse(event.body);

  // Validar CPF
  if (!isValidCPF(cpf)) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "CPF inválido" }),
    };
  }

  // Verificar se já existe
  const existingUser = await checkUserByCPF(cpf);
  if (existingUser) {
    return {
      statusCode: 409,
      body: JSON.stringify({ error: "Cliente já cadastrado" }),
    };
  }

  // Criar usuário no Cognito
  const params = {
    UserPoolId: process.env.USER_POOL_ID,
    Username: cpf,
    UserAttributes: [
      { Name: "preferred_username", Value: cpf },
      { Name: "name", Value: name },
      { Name: "family_name", Value: familyName },
      { Name: "custom:cpf", Value: cpf },
      { Name: "custom:customer_type", Value: customerType || "Regular" },
      { Name: "custom:customer_id", Value: generateCustomerId() },
    ],
    MessageAction: "SUPPRESS", // Não enviar email de boas-vindas
  };

  try {
    const result = await cognito.adminCreateUser(params).promise();

    // Marcar como confirmado (sem necessidade de senha)
    await cognito
      .adminSetUserPassword({
        UserPoolId: process.env.USER_POOL_ID,
        Username: cpf,
        Password: generateTempPassword(), // Senha temporária não usada
        Permanent: true,
      })
      .promise();

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: "Cliente registrado com sucesso",
        customerId: result.User.Attributes.find(
          (attr) => attr.Name === "custom:customer_id"
        ).Value,
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Erro interno do servidor" }),
    };
  }
};
```

### 2. Autenticação com CPF (Frontend)

```javascript
// Frontend - Autenticação apenas com CPF
import { Auth } from "aws-amplify";

async function authenticateWithCPF(cpf) {
  try {
    // Validar formato do CPF
    if (!isValidCPFFormat(cpf)) {
      throw new Error("Formato de CPF inválido");
    }

    // Iniciar autenticação customizada
    const challengeResponse = await Auth.sendCustomChallengeAnswer(
      {}, // Usuário será determinado pelo CPF
      cpf // CPF como resposta ao desafio
    );

    if (challengeResponse.challengeName === "CUSTOM_CHALLENGE") {
      // Enviar CPF como resposta ao desafio
      const authResult = await Auth.sendCustomChallengeAnswer(
        challengeResponse,
        cpf
      );

      if (authResult.getAccessToken) {
        // Sucesso - obter tokens
        const session = await Auth.currentSession();
        const idToken = session.getIdToken().getJwtToken();
        const accessToken = session.getAccessToken().getJwtToken();

        return {
          success: true,
          idToken,
          accessToken,
          user: session.getIdToken().payload,
        };
      }
    }

    throw new Error("Falha na autenticação");
  } catch (error) {
    return {
      success: false,
      error: error.message,
    };
  }
}

// Função utilitária para validar CPF
function isValidCPFFormat(cpf) {
  const cleanCPF = cpf.replace(/[^\d]/g, "");
  return cleanCPF.length === 11 && /^\d{11}$/.test(cleanCPF);
}

// Uso no componente React
const LoginComponent = () => {
  const [cpf, setCpf] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);

    const result = await authenticateWithCPF(cpf);

    if (result.success) {
      // Salvar tokens e redirecionar
      localStorage.setItem("accessToken", result.accessToken);
      localStorage.setItem("idToken", result.idToken);
      window.location.href = "/dashboard";
    } else {
      alert(`Erro: ${result.error}`);
    }

    setLoading(false);
  };

  return (
    <form onSubmit={handleLogin}>
      <input
        type="text"
        placeholder="Digite seu CPF"
        value={cpf}
        onChange={(e) => setCpf(e.target.value)}
        maxLength="14"
      />
      <button type="submit" disabled={loading}>
        {loading ? "Autenticando..." : "Entrar"}
      </button>
    </form>
  );
};
```

### 3. Integração com API Gateway

```javascript
// API Gateway Lambda Authorizer para validar JWT
exports.handler = async (event) => {
  try {
    // Extrair token do header
    const authHeader =
      event.headers.Authorization || event.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new Error("Token não fornecido");
    }

    const token = authHeader.substring(7);

    // Validar JWT token
    const decoded = await verifyJWTToken(token);

    // Extrair informações do cliente
    const customerInfo = {
      cpf: decoded["custom:cpf"],
      customerId: decoded["custom:customer_id"],
      customerType: decoded["custom:customer_type"],
      name: decoded.name,
    };

    // Gerar política de autorização
    const policy = generatePolicy(
      decoded.sub,
      "Allow",
      event.routeArn,
      customerInfo
    );

    return policy;
  } catch (error) {
    console.error("Erro na autorização:", error);
    throw new Error("Unauthorized");
  }
};

// Função para verificar JWT
async function verifyJWTToken(token) {
  const jwt = require("jsonwebtoken");
  const jwksClient = require("jwks-rsa");

  const client = jwksClient({
    jwksUri: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.USER_POOL_ID}/.well-known/jwks.json`,
  });

  return new Promise((resolve, reject) => {
    jwt.verify(
      token,
      (header, callback) => {
        client.getSigningKey(header.kid, (err, key) => {
          if (err) {
            callback(err);
          } else {
            callback(null, key.publicKey || key.rsaPublicKey);
          }
        });
      },
      {
        issuer: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.USER_POOL_ID}`,
        algorithms: ["RS256"],
      },
      (err, decoded) => {
        if (err) {
          reject(err);
        } else {
          resolve(decoded);
        }
      }
    );
  });
}

// Gerar política IAM para API Gateway
function generatePolicy(principalId, effect, resource, context) {
  return {
    principalId: principalId,
    policyDocument: {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "execute-api:Invoke",
          Effect: effect,
          Resource: resource,
        },
      ],
    },
    context: context, // Dados do cliente disponíveis nas Lambdas
  };
}
```

## 📊 Atributos do Cliente (CPF-Based)

### Atributos Obrigatórios

- `preferred_username`: CPF (identificador único)
- `custom:cpf`: CPF normalizado (backup)
- `name`: Nome do cliente

### Atributos Opcionais

- `family_name`: Sobrenome
- `custom:customer_type`: Tipo de cliente (VIP, Regular, etc.)
- `custom:customer_id`: ID único gerado pelo sistema
- `custom:preferences`: Preferências em JSON

### Estrutura do JWT Token

```json
{
  "sub": "12345678-1234-1234-1234-123456789012",
  "aud": "1example23456789",
  "cognito:username": "12345678901",
  "preferred_username": "12345678901",
  "name": "João Silva",
  "family_name": "Silva",
  "custom:cpf": "12345678901",
  "custom:customer_id": "CUST_001234",
  "custom:customer_type": "Regular",
  "iat": 1623456789,
  "exp": 1623460389,
  "token_use": "id"
}
```

## 🚀 Deploy e Configuração

### 1. Deploy da Infraestrutura

```bash
cd terraform/aws/main
terraform init
terraform plan -var-file="../env/prod.tfvars"
terraform apply -var-file="../env/prod.tfvars"
```

### 2. Configurar Lambda Triggers

Após o deploy, configurar os triggers do Cognito:

```bash
# Obter outputs do Terraform
terraform output cognito_user_pools

# Configurar Lambda triggers via AWS CLI
aws cognito-idp update-user-pool \
  --user-pool-id us-east-1_XXXXXXXX \
  --lambda-config \
  CreateAuthChallenge=arn:aws:lambda:us-east-1:123456789012:function:createAuthChallenge \
  DefineAuthChallenge=arn:aws:lambda:us-east-1:123456789012:function:defineAuthChallenge \
  VerifyAuthChallengeResponse=arn:aws:lambda:us-east-1:123456789012:function:verifyAuthChallenge
```

### 3. Configurar Frontend para CPF Auth

```javascript
// src/config/cognito.js
import { Amplify } from "aws-amplify";

Amplify.configure({
  Auth: {
    region: "us-east-1",
    userPoolId: "us-east-1_XXXXXXXX",
    userPoolWebClientId: "XXXXXXXXXXXXXXXXXXXXXXXX",
    authenticationFlowType: "CUSTOM_AUTH", // Importante para auth customizada
    oauth: {
      domain: "stackfood-prod.auth.us-east-1.amazoncognito.com",
      scope: ["openid", "profile"],
      redirectSignIn: "http://localhost:3000/callback",
      redirectSignOut: "http://localhost:3000/logout",
      responseType: "token", // Para implicit flow
    },
  },
});
```

### 4. Exemplo de API Gateway Route

```yaml
# serverless.yml ou CloudFormation
Resources:
  CustomerAuthRoute:
    Type: AWS::ApiGateway::Resource
    Properties:
      RestApiId: !Ref StackFoodAPI
      ParentId: !GetAtt StackFoodAPI.RootResourceId
      PathPart: "customers"

  CustomerAuthMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref StackFoodAPI
      ResourceId: !Ref CustomerAuthRoute
      HttpMethod: GET
      AuthorizationType: CUSTOM
      AuthorizerId: !Ref CognitoAuthorizer
      Integration:
        Type: AWS_PROXY
        IntegrationHttpMethod: POST
        Uri: !Sub "arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${CustomerLookupFunction.Arn}/invocations"

  CognitoAuthorizer:
    Type: AWS::ApiGateway::Authorizer
    Properties:
      Name: CognitoJWTAuthorizer
      Type: COGNITO_USER_POOLS
      IdentitySource: method.request.header.Authorization
      RestApiId: !Ref StackFoodAPI
      ProviderARNs:
        - !GetAtt CognitoUserPool.Arn
```

## 📈 Fluxo de Trabalho Completo

### 1. Registro de Cliente (Backend)

```bash
# POST /api/customers/register
curl -X POST https://api.stackfood.com/customers/register \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "name": "João",
    "familyName": "Silva",
    "customerType": "Regular"
  }'
```

### 2. Autenticação (Frontend)

```bash
# Usuário insere CPF no frontend
# Sistema faz autenticação customizada
# Retorna JWT token
```

### 3. Acesso à API (Com JWT)

```bash
# GET /api/customers/{cpf}
curl -X GET https://api.stackfood.com/customers/12345678901 \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIs..."
```

## 🔧 Troubleshooting Específico

### Problemas Comuns com CPF Auth

1. **Custom Auth Challenge Failed**

   - Verificar se Lambda triggers estão configuradas
   - Validar formato do CPF
   - Confirmar que usuário existe no User Pool

2. **JWT Token Inválido**

   - Verificar configuração do User Pool ID
   - Confirmar que cliente tem permissões corretas
   - Validar algoritmo de assinatura (RS256)

3. **CPF Not Found**
   - Verificar se usuário foi criado via `adminCreateUser`
   - Confirmar atributo `custom:cpf` está preenchido
   - Validar política de criação de usuários

### Debug Commands

```bash
# Verificar usuário por CPF
aws cognito-idp admin-get-user \
  --user-pool-id us-east-1_XXXXXXXX \
  --username "12345678901"

# Listar usuários
aws cognito-idp list-users \
  --user-pool-id us-east-1_XXXXXXXX \
  --filter "preferred_username=\"12345678901\""

# Testar autenticação customizada
aws cognito-idp admin-initiate-auth \
  --user-pool-id us-east-1_XXXXXXXX \
  --client-id XXXXXXXXXXXXXXXXXXXXXXXX \
  --auth-flow CUSTOM_AUTH \
  --auth-parameters USERNAME="12345678901"
```

## 📈 Monitoramento e Logs

### CloudWatch Logs

- Login attempts (success/failure)
- Password reset requests
- User registration events
- Lambda trigger executions

### Métricas Importantes

- Daily/Monthly Active Users
- Authentication success rate
- Password reset frequency
- Token refresh patterns

## 🔧 Troubleshooting

### Problemas Comuns

1. **Token Expirado**

   - Verificar configuração de validade dos tokens
   - Implementar refresh automático

2. **CORS Issues**

   - Verificar domínios permitidos no cliente
   - Configurar callback URLs corretamente

3. **Política de Senha**
   - Usuário deve atender todos os requisitos
   - Verificar mensagens de erro específicas

### Debug Commands

```bash
# Verificar User Pool
aws cognito-idp describe-user-pool --user-pool-id us-east-1_XXXXXXXX

# Verificar cliente
aws cognito-idp describe-user-pool-client --user-pool-id us-east-1_XXXXXXXX --client-id XXXXXXXXXXXXXXXXXXXXXXXX

# Listar usuários
aws cognito-idp list-users --user-pool-id us-east-1_XXXXXXXX
```

## 📚 Próximos Passos para Implementação

### 1. **Implementar Lambda Functions de Autenticação** ⚡

```bash
# Criar funções Lambda para Custom Auth
- createAuthChallenge.js
- defineAuthChallenge.js
- verifyAuthChallengeResponse.js
- customerRegistration.js
```

### 2. **Configurar API Gateway Routes** 🛤️

```bash
# Endpoints necessários
POST /auth/cpf           # Autenticação com CPF
GET  /customers/{cpf}    # Consulta cliente por CPF
POST /customers/register # Registro de novo cliente
```

### 3. **Implementar Frontend de Autenticação** 🖥️

```bash
# Componentes React/Vue
- CPFLoginForm.js
- TokenManager.js
- ProtectedRoute.js
```

### 4. **Configurar Banco de Dados** 🗄️

```bash
# Tabelas necessárias
- customers (cpf, name, family_name, customer_type)
- customer_sessions (token_id, cpf, expires_at)
```

### 5. **Testes de Integração** 🧪

```bash
# Cenários de teste
- CPF válido existente
- CPF válido não cadastrado
- CPF inválido
- Token JWT expirado
- Acesso a recursos protegidos
```

## 🎯 **Resumo da Solução CPF-Only**

✅ **Cliente insere apenas CPF** (sem senha)  
✅ **Lambda valida CPF** no banco de dados  
✅ **Cognito emite JWT** com informações do cliente  
✅ **API Gateway valida JWT** em todas as requisições  
✅ **Integração completa** com serverless architecture

### Benefícios da Arquitetura:

- 🔒 **Segurança**: JWT tokens com expiração
- 🚀 **Performance**: Stateless authentication
- 📱 **UX Simplificada**: Apenas CPF necessário
- ☁️ **Serverless**: Baixo custo e alta escalabilidade
- 🔧 **Flexibilidade**: Fácil integração com outros sistemas

---

**🔗 Recursos Adicionais:**

- [AWS Cognito Custom Auth Flow](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-challenge.html)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [API Gateway Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-lambda-authorizer-lambda-function-create.html)
