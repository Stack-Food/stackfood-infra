######################
# EKS Cluster Module #
######################

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = var.additional_security_group_ids
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
}

# KMS Key for EKS Secret Encryption
resource "aws_kms_key" "eks" {
  count = var.kms_key_arn == null ? 1 : 0

  description         = "KMS key for EKS cluster ${var.cluster_name} secret encryption"
  enable_key_rotation = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-kms-key"
      Environment = var.environment
    },
    var.tags
  )
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = var.node_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  # Use launch template for more customization if needed
  dynamic "launch_template" {
    for_each = lookup(each.value, "launch_template", null) != null ? [each.value.launch_template] : []

    content {
      id      = launch_template.value.id
      version = launch_template.value.version
    }
  }

  # Enable remote access if specified
  dynamic "remote_access" {
    for_each = lookup(each.value, "ssh_key", null) != null ? [1] : []

    content {
      ec2_ssh_key               = each.value.ssh_key
      source_security_group_ids = lookup(each.value, "source_security_group_ids", null)
    }
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = lookup(each.value, "labels", {})

  tags = merge(
    {
      Name        = "${var.cluster_name}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_cloudwatch_log_group" "existing_eks_cluster" {
  count = 1
  name  = "/aws/eks/${var.cluster_name}/cluster"
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = try(data.aws_cloudwatch_log_group.existing_eks_cluster[0].arn, null) == null ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "/aws/eks/${var.cluster_name}/cluster"
      Environment = var.environment
    },
    var.tags
  )
}
