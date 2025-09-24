output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "node_groups" {
  description = "Map of EKS Node Group ARNs"
  value = {
    for k, v in aws_eks_node_group.main : k => v.arn
  }
}

# Security Group Outputs
output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.cluster.id
}

# EKS Add-ons Outputs
output "addons" {
  description = "Map of EKS add-ons"
  value = {
    coredns = {
      arn     = aws_eks_addon.coredns.arn
      version = aws_eks_addon.coredns.addon_version
    }
    kube_proxy = {
      arn     = aws_eks_addon.kube_proxy.arn
      version = aws_eks_addon.kube_proxy.addon_version
    }
    vpc_cni = {
      arn     = aws_eks_addon.vpc_cni.arn
      version = aws_eks_addon.vpc_cni.addon_version
    }
    ebs_csi_driver = {
      arn     = aws_eks_addon.ebs_csi_driver.arn
      version = aws_eks_addon.ebs_csi_driver.addon_version
    }
  }
}

# CloudWatch Log Group Output (using EKS auto-created log group)
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (auto-created by EKS)"
  value       = "/aws/eks/${aws_eks_cluster.main.name}/cluster"
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group (auto-created by EKS)"
  value       = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${aws_eks_cluster.main.name}/cluster"
}
