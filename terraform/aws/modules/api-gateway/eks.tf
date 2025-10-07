# # Novo recurso para proxy para EKS - captura tudo que não seja /auth ou /customer
# resource "aws_api_gateway_resource" "eks_proxy" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   parent_id   = aws_api_gateway_rest_api.this.root_resource_id
#   path_part   = "{proxy+}"
# }

# # Método ANY para root path (/) - redireciona para EKS
# resource "aws_api_gateway_method" "root_any" {
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   resource_id   = aws_api_gateway_rest_api.this.root_resource_id
#   http_method   = "ANY"
#   authorization = "NONE"
# }

# # Método ANY para proxy path - redireciona para EKS
# resource "aws_api_gateway_method" "eks_proxy_any" {
#   rest_api_id   = aws_api_gateway_rest_api.this.id
#   resource_id   = aws_api_gateway_resource.eks_proxy.id
#   http_method   = "ANY"
#   authorization = "NONE"

#   request_parameters = {
#     "method.request.path.proxy" = true
#   }
# }

# # Integração HTTP para root path - vai para EKS
# resource "aws_api_gateway_integration" "root_eks_http" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_rest_api.this.root_resource_id
#   http_method = aws_api_gateway_method.root_any.http_method

#   type                    = "HTTP_PROXY"
#   integration_http_method = "ANY"
#   uri                     = "http://${data.aws_lb.eks_nlb[0].dns_name}/"
#   connection_type         = "VPC_LINK"
#   connection_id           = aws_api_gateway_vpc_link.eks.id

#   request_parameters = {
#     "integration.request.header.Host" = "'api.stackfood.com.br'"
#   }
# }

# # Integração HTTP para proxy path - vai para EKS
# resource "aws_api_gateway_integration" "eks_proxy_http" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_resource.eks_proxy.id
#   http_method = aws_api_gateway_method.eks_proxy_any.http_method

#   type                    = "HTTP_PROXY"
#   integration_http_method = "ANY"
#   uri                     = "http://${data.aws_lb.eks_nlb[0].dns_name}/{proxy}"
#   connection_type         = "VPC_LINK"
#   connection_id           = aws_api_gateway_vpc_link.eks.id

#   request_parameters = {
#     "integration.request.path.proxy"  = "method.request.path.proxy"
#     "integration.request.header.Host" = "'api.stackfood.com.br'"
#   }
# }
