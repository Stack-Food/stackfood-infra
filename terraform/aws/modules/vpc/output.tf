output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.vpc.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = [for subnet in aws_subnet.subnet-private : subnet.id]
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = [for subnet in aws_subnet.subnet-private : subnet.arn]
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = [for subnet in aws_subnet.subnet-private : subnet.cidr_block]
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = [for subnet in aws_subnet.subnet-public : subnet.id]
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = [for subnet in aws_subnet.subnet-public : subnet.arn]
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = [for subnet in aws_subnet.subnet-public : subnet.cidr_block]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = [for ngw in aws_nat_gateway.ngw : ngw.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "route_table_private_ids" {
  description = "List of IDs of private route tables"
  value       = [for rt in aws_route_table.route-table-private : rt.id]
}

output "route_table_public_id" {
  description = "ID of public route table"
  value       = aws_route_table.route-table-public.id
}
