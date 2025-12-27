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

# Deploy da API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      # Lambda routes
      aws_api_gateway_resource.auth,
      aws_api_gateway_resource.customer,
      aws_api_gateway_method.auth_post,
      aws_api_gateway_method.customer_post,
      aws_api_gateway_integration.auth_lambda,
      aws_api_gateway_integration.customer_lambda,
      aws_lambda_permission.auth_api_gateway_invoke,
      aws_lambda_permission.customer_api_gateway_invoke,
      # Microservices routes
      aws_api_gateway_resource.customers,
      aws_api_gateway_resource.products,
      aws_api_gateway_resource.orders,
      aws_api_gateway_resource.payments,
      aws_api_gateway_resource.production,
      aws_api_gateway_method.customers_any,
      aws_api_gateway_method.products_any,
      aws_api_gateway_method.orders_any,
      aws_api_gateway_method.payments_any,
      aws_api_gateway_method.production_any,
      aws_api_gateway_integration.customers_vpc_link,
      aws_api_gateway_integration.products_vpc_link,
      aws_api_gateway_integration.orders_vpc_link,
      aws_api_gateway_integration.payments_vpc_link,
      aws_api_gateway_integration.production_vpc_link
    ]))
  }

  depends_on = [
    # Lambda integrations
    aws_api_gateway_method.auth_post,
    aws_api_gateway_method.customer_post,
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.customer_lambda,
    aws_lambda_permission.auth_api_gateway_invoke,
    aws_lambda_permission.customer_api_gateway_invoke,
    # Microservices integrations
    aws_api_gateway_method.customers_any,
    aws_api_gateway_method.products_any,
    aws_api_gateway_method.orders_any,
    aws_api_gateway_method.payments_any,
    aws_api_gateway_method.production_any,
    aws_api_gateway_integration.customers_vpc_link,
    aws_api_gateway_integration.products_vpc_link,
    aws_api_gateway_integration.orders_vpc_link,
    aws_api_gateway_integration.payments_vpc_link,
    aws_api_gateway_integration.production_vpc_link
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
