# ID e ARN da API Gateway REST
output "api_gateway_id" {
  description = "The ID of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_gateway_arn" {
  description = "The ARN of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.arn
}

# Endpoint base da API
output "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway REST"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

# Stage info
output "api_gateway_stage_name" {
  description = "The stage name"
  value       = aws_api_gateway_stage.dev.stage_name
}

output "api_gateway_stage_invoke_url" {
  description = "The full invoke URL for the stage"
  value       = aws_api_gateway_stage.dev.invoke_url
}

# Lambda Permission info
output "customer_lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission"
  value       = aws_lambda_permission.customer_api_gateway_invoke.statement_id
}

output "auth_lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission"
  value       = aws_lambda_permission.auth_api_gateway_invoke.statement_id
}

# Custom domain (se estiver usando)
output "custom_domain_name" {
  description = "The custom domain name of the API Gateway"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "custom_domain_name_target_domain_name" {
  description = "The target domain name for the custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "custom_domain_name_hosted_zone_id" {
  description = "The hosted zone ID for the custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}

output "custom_domain_base_path_mapping_id" {
  description = "The ID of the base path mapping"
  value       = var.custom_domain_name != "" ? aws_api_gateway_base_path_mapping.this[0].id : null
}

# VPC Link (caso esteja integrando com NLB no EKS)
output "vpc_link_id" {
  description = "The ID of the VPC Link"
  value       = aws_api_gateway_vpc_link.eks.id
}

output "vpc_link_arn" {
  description = "The ARN of the VPC Link"
  value       = aws_api_gateway_vpc_link.eks.arn
}

# NLB debugging
output "nlb_dns_name" {
  description = "The DNS name of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].dns_name : null
}

output "nlb_arn" {
  description = "The ARN of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].arn : null
}

output "nlb_zone_id" {
  description = "The zone ID of the NGINX Ingress NLB"
  value       = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].zone_id : null
}

# ============================================
# Microservices Routes Outputs
# ============================================

output "microservices_routes" {
  description = "Map of microservices routes and their endpoints"
  value = {
    customers = {
      path      = "/customers"
      port      = 8084
      namespace = "customers"
      service   = "stackfood-customers"
      url       = "${aws_api_gateway_stage.dev.invoke_url}/customers"
    }
    products = {
      path      = "/products"
      port      = 8080
      namespace = "products"
      service   = "stackfood-products"
      url       = "${aws_api_gateway_stage.dev.invoke_url}/products"
    }
    orders = {
      path      = "/orders"
      port      = 8081
      namespace = "orders"
      service   = "stackfood-orders"
      url       = "${aws_api_gateway_stage.dev.invoke_url}/orders"
    }
    payments = {
      path      = "/payments"
      port      = 8082
      namespace = "payments"
      service   = "stackfood-payments"
      url       = "${aws_api_gateway_stage.dev.invoke_url}/payments"
    }
    production = {
      path      = "/production"
      port      = 8083
      namespace = "production"
      service   = "stackfood-production"
      url       = "${aws_api_gateway_stage.dev.invoke_url}/production"
    }
  }
}

output "api_routes_summary" {
  description = "Summary of all API Gateway routes"
  value = {
    base_url = aws_api_gateway_stage.dev.invoke_url
    custom_domain = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : null
    routes = {
      lambda = {
        auth     = "/auth"
        customer = "/customer"
      }
      microservices = {
        customers  = "/customers/{proxy+}"
        products   = "/products/{proxy+}"
        orders     = "/orders/{proxy+}"
        payments   = "/payments/{proxy+}"
        production = "/production/{proxy+}"
      }
    }
    vpc_link_enabled = true
    vpc_link_id      = aws_api_gateway_vpc_link.eks.id
  }
}
