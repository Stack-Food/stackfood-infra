output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

# Note: We don't output the password for security reasons
output "db_username" {
  description = "The database username"
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "The ARN of the master user secret (when manage_master_user_password is true)"
  value       = aws_db_instance.this.master_user_secret
}

output "master_user_secret_kms_key_id" {
  description = "The KMS key ID used to encrypt the master user secret"
  value       = length(aws_db_instance.this.master_user_secret) > 0 ? aws_db_instance.this.master_user_secret[0].kms_key_id : null
}

output "db_subnet_group_id" {
  description = "The db subnet group id"
  value       = aws_db_subnet_group.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.this.id
}
