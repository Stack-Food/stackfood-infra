###########################
# Application User Pool   #
###########################

resource "aws_cognito_user_pool" "app" {
  count = var.create_app_user_pool ? 1 : 0

  name = "${var.user_pool_name}-app"
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
    Name        = "${var.user_pool_name}-app"
    Environment = var.environment
    Service     = "Application"
    Purpose     = "API Gateway Authentication"
  }
}

###########################
# Cognito User Pool Client #
###########################

resource "aws_cognito_user_pool_client" "app" {
  count = var.create_app_user_pool ? 1 : 0

  name         = "${var.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.app[0].id

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
    "ALLOW_USER_PASSWORD_AUTH", # Para autenticação padrão
    "ALLOW_CUSTOM_AUTH",        # Para autenticação customizada com CPF
    "ALLOW_REFRESH_TOKEN_AUTH"  # Para renovar tokens
  ]

  # Prevenir vazamento de informações sobre existência de usuários
  prevent_user_existence_errors = "ENABLED"


  # Atributos que podem ser lidos
  read_attributes = ["custom:cpf", "preferred_username", "email"]
}


###########################
# Cognito Guest User      #
###########################

resource "aws_cognito_user" "guest" {
  count = var.create_app_user_pool ? 1 : 0

  user_pool_id = aws_cognito_user_pool.app[0].id
  username     = "convidado"
  password     = var.guest_user_password

  # Suprime o e-mail de boas-vindas, o que, em conjunto com a definição da senha,
  # cria o usuário com o status CONFIRMED, tornando a senha "permanente"
  # e não exigindo alteração no primeiro login.
  message_action = "SUPPRESS"

  attributes = {
    name  = "Usuário Convidado"
    email = "convidado@example.com"
    # O Cognito requer que o e-mail seja verificado para algumas operações,
    # mas para um usuário interno/convidado, podemos marcá-lo como verificado.
    email_verified = true
  }
}
