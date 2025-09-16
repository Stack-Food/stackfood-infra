resource "aws_eks_access_entry" "eks-access-entry" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::623941524506:role/voclabs"
  #kubernetes_groups = ["system:masters"]
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks-cluster-admin-policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::623941524506:role/voclabs"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "eks-admin-policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = "arn:aws:iam::623941524506:role/voclabs"

  access_scope {
    type = "cluster"
  }
}
