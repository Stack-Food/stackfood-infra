resource "null_resource" "wait_for_nlb" {
  triggers = {
    nlb_arn = data.aws_lb.eks_nlb[0].arn
  }

  provisioner "local-exec" {
    command = <<EOT
      for i in $(seq 1 60); do
        state=$(aws elbv2 describe-load-balancers --load-balancer-arns ${data.aws_lb.eks_nlb[0].arn} --region ${data.aws_region.current.region} --query 'LoadBalancers[0].State.Code' --output text)
        if [ "$state" = "active" ]; then
          exit 0
        fi
        sleep 15
      done
      exit 1
    EOT
  }
}

# VPC Link para conectar API Gateway com EKS (se especificado)
resource "aws_api_gateway_vpc_link" "eks" {

  name        = "${var.api_name}-eks-vpc-link"
  description = "VPC Link for ${var.api_name} to connect to EKS cluster ${var.eks_cluster_name}"
  target_arns = length(data.aws_lb.eks_nlb) > 0 ? [data.aws_lb.eks_nlb[0].arn] : []

  tags = merge(
    {
      Name        = "${var.api_name}-eks-vpc-link"
      Environment = var.environment
      Cluster     = var.eks_cluster_name
    },
    var.tags
  )
  depends_on = [null_resource.wait_for_nlb]
}
