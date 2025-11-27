# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-coredns"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-kube-proxy"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-vpc-cni"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}

# EBS CSI Driver - DISABLED for AWS Academy
# AWS Academy does not support OIDC Identity Providers required for IRSA
# Error: No OpenIDConnect provider found in your account
# Workaround: Using emptyDir volumes instead of persistent EBS volumes
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi_driver.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true
  service_account_role_arn    = data.aws_iam_role.eks_node_role.arn

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "metrics-server"
  addon_version               = data.aws_eks_addon_version.metrics_server.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_eks_addon" "prometheus_node_exporter" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "prometheus-node-exporter"
  addon_version               = data.aws_eks_addon_version.prometheus_node_exporter.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  preserve                    = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [
    aws_eks_cluster.main
  ]
}
