data "aws_region" "current" {}

# Data source para buscar o Network Load Balancer do EKS NGINX Ingress
# Busca por NLB criado pelo NGINX Ingress Controller
data "aws_lb" "eks_nlb" {
  count = var.eks_cluster_name != null ? 1 : 0

  tags = {
    "kubernetes.io/service-name"                    = "ingress-nginx/ingress-nginx-controller"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

# Fallback: buscar por tags alternativas se o primeiro não funcionar
data "aws_lbs" "nginx_nlbs" {
  count = var.eks_cluster_name != null && length(data.aws_lb.eks_nlb) == 0 ? 1 : 0

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "kubernetes.io/service-name"                    = "ingress-nginx/ingress-nginx-controller"
  }
}

# Data source adicional para buscar por nome do serviço
data "aws_lbs" "nginx_nlbs_alt" {
  count = var.eks_cluster_name != null ? 1 : 0

  tags = {
    "service.k8s.aws/stack" = "ingress-nginx/ingress-nginx-controller"
  }
}

data "aws_lb_listener" "selected443" {
  count = length(data.aws_lb.eks_nlb) > 0 ? 1 : 0

  load_balancer_arn = data.aws_lb.eks_nlb[0].arn
  port              = 443
}

data "aws_lb_listener" "selected80" {
  count = length(data.aws_lb.eks_nlb) > 0 ? 1 : 0

  load_balancer_arn = data.aws_lb.eks_nlb[0].arn
  port              = 80
}
