#############################################
# API Gateway Routes for Microservices
# Routes all microservices through VPC Link to NLB
#############################################

# Dynamic resource creation for each microservice
resource "aws_api_gateway_resource" "microservice" {
  for_each = var.microservices

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path
}

# Dynamic proxy resource for each microservice
resource "aws_api_gateway_resource" "microservice_proxy" {
  for_each = var.microservices

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.microservice[each.key].id
  path_part   = "{proxy+}"
}

# Dynamic ANY method for each microservice
resource "aws_api_gateway_method" "microservice_any" {
  for_each = var.microservices

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Dynamic VPC Link integration for each microservice pointing to NLB
resource "aws_api_gateway_integration" "microservice_vpc_link" {
  for_each = var.microservices

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method = aws_api_gateway_method.microservice_any[each.key].http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  # Point to NLB instead of internal Kubernetes service
  uri             = "http://${var.nlb_dns_name}/${each.value.path}/{proxy}"
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks.id

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  cache_key_parameters = ["method.request.path.proxy"]
}
