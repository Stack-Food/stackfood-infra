######################
# EKS Cluster Module #
######################

# Note: CloudWatch Log Group will be created automatically by EKS
# when enabled_cluster_log_types is specified in the EKS cluster resource

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode = var.authentication_mode
  }

  vpc_config {
    subnet_ids              = var.public_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.cluster.id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn
    }
  }

  # Enable EKS Control Plane Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(
    {
      Name        = var.cluster_name
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = false
  }
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = var.public_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = 1
  }

  #release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  labels = lookup(each.value, "labels", {})

  # Support for taints (for dedicated workloads like RabbitMQ)
  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )

  # Ensure proper creation order and avoid dependency cycles
  depends_on = [
    aws_eks_cluster.main,
    data.aws_iam_role.eks_cluster_role,
    data.aws_iam_role.eks_node_role
  ]

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}
