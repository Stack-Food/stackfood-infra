# Data Sources
data "aws_caller_identity" "current" {}

# Data source para obter a IAM role existente para o cluster EKS
data "aws_iam_role" "eks_cluster_role" {
  name = var.cluster_role_name
}

# Data source para obter a IAM role existente para os nodes do EKS
data "aws_iam_role" "eks_node_role" {
  name = var.node_role_name
}
