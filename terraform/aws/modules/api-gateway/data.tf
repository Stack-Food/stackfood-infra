# Data sources para buscar ARN da Lambda (se especificada)
data "aws_lambda_function" "this" {
  count         = var.lambda_function_name != null ? 1 : 0
  function_name = var.lambda_function_name
}

# Data source para buscar o Network Load Balancer do EKS (se especificado)
data "aws_lb" "eks_nlb" {
  count = var.eks_cluster_name != null ? 1 : 0

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "kubernetes.io/service-name"                    = "default/api-gateway-nlb"
  }
}

data "aws_region" "current" {}
