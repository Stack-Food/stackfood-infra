# Data Sources for EKS Module

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get the AWS region
data "aws_region" "current" {}

# Data source para obter a IAM role existente para o cluster EKS
data "aws_iam_role" "eks_cluster_role" {
  name = var.cluster_role_name
}

# Data source para obter a IAM role existente para os nodes do EKS
data "aws_iam_role" "eks_node_role" {
  name = var.node_role_name
}

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.main.version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
}

# Data sources for EKS Add-on versions
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "metrics_server" {
  addon_name         = "metrics-server"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

data "aws_eks_addon_version" "prometheus_node_exporter" {
  addon_name         = "prometheus-node-exporter"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}
