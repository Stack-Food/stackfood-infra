data "aws_lb" "eks_nlb" {
  count = var.eks_cluster_name != null ? 1 : 0

  tags = {
    "kubernetes.io/service-name"                    = "ingress-nginx/ingress-nginx-controller"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}
