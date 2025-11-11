resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "REST API integrada com Lambda"
}

# recurso /auth
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "customer" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "customer"
}

resource "aws_api_gateway_method" "customer_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.customer.id
  http_method   = "POST"
  authorization = "NONE"
}


# integração com Lambda
resource "aws_api_gateway_integration" "customer_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.customer.id
  http_method             = aws_api_gateway_method.customer_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Lambda Permission - permite que API Gateway invoque a Lambda
resource "aws_lambda_permission" "customer_api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway-Customer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${aws_api_gateway_method.customer_post.http_method}${aws_api_gateway_resource.customer.path}"

  lifecycle {
    create_before_destroy = true
  }
}

# método POST /auth
resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "NONE"
}

# integração com Lambda
resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.auth_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Lambda Permission - permite que API Gateway invoque a Lambda
resource "aws_lambda_permission" "auth_api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway-Auth"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${aws_api_gateway_method.auth_post.http_method}${aws_api_gateway_resource.auth.path}"

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# EKS Integration Resources
# ==========================================

# Resource para capturar todos os outros paths (proxy para EKS)
resource "aws_api_gateway_resource" "eks_proxy" {
  count       = var.eks_cluster_name != null ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

# Método ANY para o proxy (aceita todos os métodos HTTP)
resource "aws_api_gateway_method" "eks_proxy_any" {
  count         = var.eks_cluster_name != null ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.eks_proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integração HTTP_PROXY com EKS através do VPC Link
resource "aws_api_gateway_integration" "eks_proxy" {
  count                   = var.eks_cluster_name != null ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.eks_proxy[0].id
  http_method             = aws_api_gateway_method.eks_proxy_any[0].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"

  # URI do NLB criado pelo NGINX Ingress
  uri = "${local.integration_uri}:${local.integration_port}/{proxy}"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks.id

  request_parameters = {
    "integration.request.path.proxy"  = "method.request.path.proxy"
    "integration.request.header.Host" = "'${var.custom_domain_name}'"
  }

  # Timeout de 29 segundos (máximo permitido)
  timeout_milliseconds = 29000
}

# Método OPTIONS para CORS no proxy
resource "aws_api_gateway_method" "eks_proxy_options" {
  count         = var.eks_cluster_name != null ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.eks_proxy[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração MOCK para OPTIONS (resposta CORS)
resource "aws_api_gateway_integration" "eks_proxy_options" {
  count       = var.eks_cluster_name != null ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.eks_proxy[0].id
  http_method = aws_api_gateway_method.eks_proxy_options[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Response para OPTIONS
resource "aws_api_gateway_method_response" "eks_proxy_options" {
  count       = var.eks_cluster_name != null ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.eks_proxy[0].id
  http_method = aws_api_gateway_method.eks_proxy_options[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# Integration Response para OPTIONS
resource "aws_api_gateway_integration_response" "eks_proxy_options" {
  count       = var.eks_cluster_name != null ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.eks_proxy[0].id
  http_method = aws_api_gateway_method.eks_proxy_options[0].http_method
  status_code = aws_api_gateway_method_response.eks_proxy_options[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,PATCH,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.eks_proxy_options
  ]
}

# Deploy da API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.auth,
      aws_api_gateway_resource.customer,
      aws_api_gateway_method.auth_post,
      aws_api_gateway_method.customer_post,
      aws_api_gateway_integration.auth_lambda,
      aws_api_gateway_integration.customer_lambda,
      aws_lambda_permission.auth_api_gateway_invoke,
      aws_lambda_permission.customer_api_gateway_invoke,
      # EKS integration resources
      var.eks_cluster_name != null ? aws_api_gateway_resource.eks_proxy[0].id : "",
      var.eks_cluster_name != null ? aws_api_gateway_method.eks_proxy_any[0].id : "",
      var.eks_cluster_name != null ? aws_api_gateway_integration.eks_proxy[0].id : "",
    ]))
  }

  depends_on = [
    aws_api_gateway_method.auth_post,
    aws_api_gateway_method.customer_post,
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.customer_lambda,
    aws_lambda_permission.auth_api_gateway_invoke,
    aws_lambda_permission.customer_api_gateway_invoke,
    # EKS integration dependencies
    aws_api_gateway_integration.eks_proxy,
    aws_api_gateway_integration.eks_proxy_options
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Stage dev
resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
}


resource "aws_api_gateway_domain_name" "this" {
  count                    = var.custom_domain_name != "" ? 1 : 0
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Base Path Mapping - conecta o custom domain ao stage da API
resource "aws_api_gateway_base_path_mapping" "this" {
  count       = var.custom_domain_name != "" ? 1 : 0
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  base_path   = var.base_path

  depends_on = [
    aws_api_gateway_domain_name.this,
    aws_api_gateway_stage.dev
  ]
}
