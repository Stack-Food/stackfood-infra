# Data Sources 

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get the AWS region
data "aws_region" "current" {}

# Get current AWS partition
data "aws_partition" "current" {}

data "aws_iam_role" "eks_cluster_role" {
  name = var.eks_cluster_role_name
}
