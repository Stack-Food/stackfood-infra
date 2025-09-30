# resource "aws_api_gateway_rest_api" "main" {
#   name        = var.api_name
#   description = var.description

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
# }

# resource "aws_api_gateway_resource" "this" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   parent_id   = aws_api_gateway_rest_api.main.root_resource_id
#   path_part   = "{proxy+}"
# }

# # Method para o resource proxy
# resource "aws_api_gateway_method" "this" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_resource.this.id
#   http_method   = "ANY"
#   authorization = "NONE"

#   # Remova os parâmetros relacionados à Authorization
#   request_parameters = {
#     "method.request.path.proxy" = true
#     # Removido: "method.request.header.Authorization" = true
#   }
# }

# # Method para o root resource (/)
# resource "aws_api_gateway_method" "root" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_rest_api.main.root_resource_id
#   http_method   = "ANY"
#   authorization = "NONE"
# }

# # Integration para o resource proxy
# resource "aws_api_gateway_integration" "proxy" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_resource.this.id
#   http_method = aws_api_gateway_method.this.http_method

#   integration_http_method = "GET"
#   type                    = "HTTP_PROXY"
#   uri                     = "https://myapp.stackfood.com.br/{proxy}"
#   passthrough_behavior    = "WHEN_NO_MATCH"
#   content_handling        = "CONVERT_TO_TEXT"

#   # Remova os parâmetros relacionados à Authorization
#   request_parameters = {
#     "integration.request.path.proxy"    = "method.request.path.proxy"
#     "integration.request.header.Accept" = "'application/json'"
#   }

#   connection_type = "VPC_LINK"
#   connection_id   = aws_api_gateway_vpc_link.eks.id
# }

# # Integration para o root resource
# resource "aws_api_gateway_integration" "root" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_rest_api.main.root_resource_id
#   http_method = aws_api_gateway_method.root.http_method

#   integration_http_method = "ANY"
#   type                    = "HTTP_PROXY"
#   uri                     = "https://myapp.stackfood.com.br/"
#   passthrough_behavior    = "WHEN_NO_MATCH"
#   content_handling        = "CONVERT_TO_TEXT"

#   request_parameters = {
#     "integration.request.header.Accept" = "'application/json'"
#   }

#   connection_type = "VPC_LINK"
#   connection_id   = aws_api_gateway_vpc_link.eks.id
# }

# # Deployment (corrigido)
# resource "aws_api_gateway_deployment" "this" {
#   depends_on = [
#     aws_api_gateway_integration.proxy,
#     aws_api_gateway_integration.root,
#   ]

#   rest_api_id = aws_api_gateway_rest_api.main.id

#   # Trigger corrigido
#   triggers = {
#     redeployment = sha1(jsonencode([
#       aws_api_gateway_resource.this.id,
#       aws_api_gateway_method.this.id,
#       aws_api_gateway_method.root.id,
#       aws_api_gateway_integration.proxy.id,
#       aws_api_gateway_integration.root.id,
#     ]))
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_api_gateway_stage" "this" {
#   deployment_id = aws_api_gateway_deployment.this.id
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   stage_name    = "v1"
# }

# # Domain Name
# resource "aws_api_gateway_domain_name" "this" {
#   domain_name              = "api.stackfood.com.br"
#   regional_certificate_arn = var.acm_certificate_arn

#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }

#   security_policy = "TLS_1_2"
# }

# # Base Path Mapping
# resource "aws_api_gateway_base_path_mapping" "this" {
#   api_id      = aws_api_gateway_rest_api.main.id
#   stage_name  = aws_api_gateway_stage.this.stage_name
#   domain_name = aws_api_gateway_domain_name.this.domain_name
# }
