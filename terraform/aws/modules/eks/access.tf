resource "aws_eks_access_entry" "eks-access-entry" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"
  #kubernetes_groups = ["system:masters"]
  type = "STANDARD"
}

# Access entry for LabRole (used by node groups)
resource "aws_eks_access_entry" "node-access-entry" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  type          = "EC2_LINUX"
}

resource "aws_eks_access_policy_association" "eks-cluster-admin-policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "eks-admin-policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"

  access_scope {
    type = "cluster"
  }
}

# Node access policy for LabRole
resource "aws_eks_access_policy_association" "node-worker-policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSWorkerNodePolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  access_scope {
    type = "cluster"
  }
}
