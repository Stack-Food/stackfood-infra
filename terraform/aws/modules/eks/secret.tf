# KMS Key for EKS Secret Encryption (created early to avoid dependencies)
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

resource "aws_kms_alias" "eks" {
  count         = var.kms_key_arn == null ? 1 : 0
  name          = "alias/eks-${var.cluster_name}"
  target_key_id = aws_kms_key.eks[0].key_id
}
