resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  region        = data.aws_region.current.region
  description   = "Stackfood API Gateway integrated with EKS NLB"
  cors_configuration {
    allow_credentials = var.cors_configuration.allow_credentials
    allow_headers     = var.cors_configuration.allow_headers
    allow_methods     = var.cors_configuration.allow_methods
    allow_origins     = var.cors_configuration.allow_origins
    expose_headers    = var.cors_configuration.expose_headers
    max_age           = var.cors_configuration.max_age
  }
}
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.stage_name
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "this" {
  api_id = aws_apigatewayv2_api.main.id

  # Usar HTTP_PROXY para redirecionar para o NLB do NGINX Ingress
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  # URI do NLB do NGINX Ingress usando locals
  integration_uri = data.aws_lb_listener.selected80[0].arn

  # Usar VPC Link para conectar privadamente
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.eks.id

  # Configurações de request/response - simplificadas para evitar problemas com cabeçalhos restritos
  request_parameters = {
    "overwrite:header.Host" = "api.stackfood.com.br"
  }
}

resource "aws_apigatewayv2_route" "catch_all" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_domain_name" "this" {
  count       = var.custom_domain_name != "" ? 1 : 0
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count       = var.custom_domain_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.this.id
}
