resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_leo_cluster.name
  node_group_name = "nodeg-${var.project_name}"
  node_role_arn   = var.labRole
  subnet_ids      = aws_subnet.subnet_public[*].id
  capacity_type   = "SPOT"

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }


  tags = var.tags

}