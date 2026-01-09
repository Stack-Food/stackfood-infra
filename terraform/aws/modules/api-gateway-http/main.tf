resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.name}-vpc-link"
  subnet_ids         = var.public_subnet_ids
  security_group_ids = [var.cluster_security_group_ids]
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.this.id

  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.http.arn

  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_security_group" "apigw_vpc_link" {
  name   = "apigw-vpc-link"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ========================================
# Lambda Integration Resources
# ========================================

# Lambda Integration for /auth endpoint
resource "aws_apigatewayv2_integration" "auth_lambda" {
  count = var.enable_lambda_integration ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arn

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# Route for POST /auth
resource "aws_apigatewayv2_route" "auth_post" {
  count = var.enable_lambda_integration ? 1 : 0

  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda[0].id}"
}

# Lambda Integration for /customer endpoint
resource "aws_apigatewayv2_integration" "customer_lambda" {
  count = var.enable_lambda_integration ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arn

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# Route for POST /customer
resource "aws_apigatewayv2_route" "customer_post" {
  count = var.enable_lambda_integration ? 1 : 0

  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /customer"
  target    = "integrations/${aws_apigatewayv2_integration.customer_lambda[0].id}"
}

# Lambda Permission for /auth route
resource "aws_lambda_permission" "auth_api_gateway_invoke" {
  count = var.enable_lambda_integration ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGatewayV2-Auth"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/auth"

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda Permission for /customer route
resource "aws_lambda_permission" "customer_api_gateway_invoke" {
  count = var.enable_lambda_integration ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGatewayV2-Customer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/customer"

  lifecycle {
    create_before_destroy = true
  }
}

