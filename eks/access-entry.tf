resource "aws_eks_access_entry" "eks-access-entry" {
  cluster_name      = aws_eks_cluster.eks_leo_cluster.name
  principal_arn     = var.principalArn
  kubernetes_groups = ["leo"]
  type              = "STANDARD"
}
