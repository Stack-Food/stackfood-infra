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

output "node_security_group_id" {
  description = "Security group ID attached to the EKS workers"
  value       = aws_security_group.node.id
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

# Load Balancer Outputs
output "internal_alb_arn" {
  description = "ARN of the internal ALB"
  value       = var.create_internal_alb ? aws_lb.internal[0].arn : null
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = var.create_internal_alb ? aws_lb.internal[0].dns_name : null
}

output "internal_alb_zone_id" {
  description = "Zone ID of the internal ALB"
  value       = var.create_internal_alb ? aws_lb.internal[0].zone_id : null
}

output "public_nlb_arn" {
  description = "ARN of the public NLB"
  value       = var.create_public_nlb ? aws_lb.public[0].arn : null
}

output "public_nlb_dns_name" {
  description = "DNS name of the public NLB"
  value       = var.create_public_nlb ? aws_lb.public[0].dns_name : null
}

# Security Group Outputs
output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "alb_internal_security_group_id" {
  description = "Security group ID for the internal ALB"
  value       = aws_security_group.alb_internal.id
}

output "nlb_public_security_group_id" {
  description = "Security group ID for the public NLB"
  value       = var.create_public_nlb ? aws_security_group.nlb_public[0].id : null
}

output "management_security_group_id" {
  description = "Security group ID for remote management"
  value       = var.enable_remote_management ? aws_security_group.management[0].id : null
}
