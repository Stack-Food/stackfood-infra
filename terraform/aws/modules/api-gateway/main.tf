############################
# API Gateway REST Module #
############################

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.this.id}/${var.stage_name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "API-Gateway-Logs-${var.api_name}-${var.stage_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  # Policy para restringir acesso se especificado
  #   dynamic "policy" {
  #     for_each = var.policy_document != null ? [1] : []
  #     content {
  #       policy = var.policy_document
  #     }
  #   }

  # Configurações de autenticação
  api_key_source = var.api_key_source

  # Binary media types if needed
  binary_media_types = var.binary_media_types

  tags = merge(
    {
      Name        = var.api_name
      Environment = var.environment
    },
    var.tags
  )
}

# API Gateway Resources dinâmicos
resource "aws_api_gateway_resource" "this" {
  for_each = var.resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = each.value.parent_id != null ? each.value.parent_id : aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

# API Gateway Methods
resource "aws_api_gateway_method" "this" {
  for_each = var.methods

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value.resource_id != null ? each.value.resource_id : aws_api_gateway_resource.this[each.value.resource_key].id
  http_method   = each.value.http_method
  authorization = each.value.authorization

  # Configurações opcionais
  authorizer_id        = each.value.authorizer_id
  authorization_scopes = each.value.authorization_scopes
  api_key_required     = each.value.api_key_required
  operation_name       = each.value.operation_name
  request_models       = each.value.request_models
  request_validator_id = each.value.request_validator_id

  # Request parameters
  request_parameters = each.value.request_parameters
}

# API Gateway Integrations (principalmente para Lambda)
resource "aws_api_gateway_integration" "this" {
  for_each = var.integrations

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id != null ? each.value.resource_id : aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.value.method_key].http_method

  integration_http_method = each.value.integration_http_method
  type                    = each.value.type
  uri                     = each.value.uri

  # Configurações opcionais
  connection_type      = each.value.connection_type
  connection_id        = each.value.connection_id
  credentials          = each.value.credentials
  request_templates    = each.value.request_templates
  request_parameters   = each.value.request_parameters
  passthrough_behavior = each.value.passthrough_behavior
  cache_key_parameters = each.value.cache_key_parameters
  cache_namespace      = each.value.cache_namespace
  content_handling     = each.value.content_handling
  timeout_milliseconds = each.value.timeout_milliseconds

  # TLS config para backends HTTPS
  dynamic "tls_config" {
    for_each = each.value.tls_config != null ? [each.value.tls_config] : []
    content {
      insecure_skip_verification = tls_config.value.insecure_skip_verification
    }
  }
}

# Method Responses
resource "aws_api_gateway_method_response" "this" {
  for_each = var.method_responses

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id != null ? each.value.resource_id : aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.value.method_key].http_method
  status_code = each.value.status_code

  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters
}

# Integration Responses
resource "aws_api_gateway_integration_response" "this" {
  for_each = var.integration_responses

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_id != null ? each.value.resource_id : aws_api_gateway_resource.this[each.value.resource_key].id
  http_method = aws_api_gateway_method.this[each.value.method_key].http_method
  status_code = aws_api_gateway_method_response.this[each.value.method_response_key].status_code

  response_templates  = each.value.response_templates
  response_parameters = each.value.response_parameters
  selection_pattern   = each.value.selection_pattern
  content_handling    = each.value.content_handling

  depends_on = [aws_api_gateway_integration.this]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  description = var.deployment_description

  # Triggers para redeploy quando configurações mudam
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body,
      aws_api_gateway_method.this,
      aws_api_gateway_integration.this,
      aws_api_gateway_method_response.this,
      aws_api_gateway_integration_response.this,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_method_response.this,
    aws_api_gateway_integration_response.this,
  ]
}

# Stage configuration
resource "aws_api_gateway_stage" "this" {
  count = var.create_stage ? 1 : 0

  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name

  description           = var.stage_description
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_size

  # Configurações de throttling
  #   dynamic "throttle_settings" {
  #     for_each = var.throttle_settings != null ? [var.throttle_settings] : []
  #     content {
  #       rate_limit  = throttle_settings.value.rate_limit
  #       burst_limit = throttle_settings.value.burst_limit
  #     }
  #   }

  # Configurações de logs
  dynamic "access_log_settings" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway.arn
      format = var.access_log_format != null ? var.access_log_format : jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
      })
    }
  }

  # Configurações de CloudWatch
  xray_tracing_enabled = var.xray_tracing_enabled

  # Variables do stage
  variables = var.stage_variables

  tags = merge(
    {
      Name        = "${var.api_name}-${var.stage_name}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_api_gateway_deployment.this]
}

# API Keys
resource "aws_api_gateway_api_key" "this" {
  for_each = var.api_keys

  name        = each.value.name
  description = each.value.description
  enabled     = each.value.enabled

  tags = merge(
    {
      Name        = each.value.name
      Environment = var.environment
      API         = var.api_name
    },
    var.tags
  )
}

# Usage Plans
resource "aws_api_gateway_usage_plan" "this" {
  for_each = var.usage_plans

  name         = each.value.name
  description  = each.value.description
  product_code = each.value.product_code

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = var.stage_name
  }

  # Quota settings
  dynamic "quota_settings" {
    for_each = each.value.quota_settings != null ? [each.value.quota_settings] : []
    content {
      limit  = quota_settings.value.limit
      period = quota_settings.value.period
      offset = quota_settings.value.offset
    }
  }

  # Throttle settings
  dynamic "throttle_settings" {
    for_each = each.value.throttle_settings != null ? [each.value.throttle_settings] : []
    content {
      rate_limit  = throttle_settings.value.rate_limit
      burst_limit = throttle_settings.value.burst_limit
    }
  }

  tags = merge(
    {
      Name        = each.value.name
      Environment = var.environment
      API         = var.api_name
    },
    var.tags
  )

  depends_on = [aws_api_gateway_stage.this]
}

# Usage Plan Keys (associação entre API Keys e Usage Plans)
resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = var.usage_plan_keys

  key_id        = aws_api_gateway_api_key.this[each.value.api_key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan].id
}

# Lambda permissions para API Gateway (quando necessário)
resource "aws_lambda_permission" "this" {
  for_each = var.lambda_permissions

  statement_id  = each.value.statement_id
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
  qualifier     = each.value.qualifier
}
