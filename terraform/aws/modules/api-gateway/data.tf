data "aws_region" "current" {}

# Data source para buscar o Network Load Balancer do EKS NGINX Ingress
data "aws_lb" "eks_nlb" {
  count = var.eks_cluster_name != null ? 1 : 0

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
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
