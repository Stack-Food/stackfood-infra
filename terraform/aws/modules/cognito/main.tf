###########################
# Cognito User Pool       #
###########################

resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name
  # Configuração para usar CPF como username (sem conflito)
  # Removemos username_attributes para evitar conflito com alias_attributes
  alias_attributes = ["preferred_username"]

  # Política de senha desabilitada para autenticação customizada
  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  # Schema customizado para CPF
  schema {
    attribute_data_type = "String"
    name                = "cpf"
    required            = false
    mutable             = false

    string_attribute_constraints {
      min_length = 11
      max_length = 11
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = false
    mutable             = false
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = false
    mutable             = false
  }

  tags = {
    Name        = var.user_pool_name
    Environment = var.environment
  }
}

###########################
# Cognito User Pool Client #
###########################

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # Não gerar secret para simplificar a integração
  generate_secret = false

  # 60 minutos (explícito)
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Fluxos de autenticação permitidos
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",       # Para autenticação customizada com CPF
    "ALLOW_REFRESH_TOKEN_AUTH" # Para renovar tokens
  ]

  # Prevenir vazamento de informações sobre existência de usuários
  prevent_user_existence_errors = "ENABLED"


  # Atributos que podem ser lidos
  read_attributes = ["custom:cpf", "preferred_username", "email"]
}
