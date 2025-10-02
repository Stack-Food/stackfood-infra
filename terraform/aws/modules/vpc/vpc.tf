###########
# AWS VPC #
###########

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_blocks[0]
  enable_dns_support   = var.vpc_enable_dns_support
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  # Flow logs for security and troubleshooting
  enable_network_address_usage_metrics = true

  tags = merge(
    {
      Name              = var.vpc_name
      Terraform_Managed = "true"
      Environment       = var.environment
    },
    var.tags
  )
}

# Subnets Privadas
resource "aws_subnet" "subnet-private" {
  for_each = var.subnets_private

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = try(each.value.availability_zone, data.aws_availability_zones.availability_zones.names[index(keys(var.subnets_private), each.key) % length(data.aws_availability_zones.availability_zones.names)])

  tags = merge(
    {
      Name                              = join("-", [var.vpc_name, "private", each.key])
      Terraform_Managed                 = "true"
      Environment                       = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.cluster_name != "" ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    } : {},
    var.tags
  )
}

# Subnets Públicas
resource "aws_subnet" "subnet-public" {
  for_each = var.subnets_public

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = try(each.value.availability_zone, data.aws_availability_zones.availability_zones.names[index(keys(var.subnets_public), each.key) % length(data.aws_availability_zones.availability_zones.names)])
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                     = join("-", [var.vpc_name, "public", each.key])
      Terraform_Managed        = "true"
      Environment              = var.environment
      "kubernetes.io/role/elb" = "1"
    },
    var.cluster_name != "" ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    } : {},
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name              = var.igw_name
    Terraform_Managed = "true"
    Environment       = var.environment
  }
}

# EIPs para NAT Gateway
resource "aws_eip" "ngw-ip" {
  domain = "vpc"

  tags = {
    Name              = join("-", [var.vpc_name, "eip", "nat"])
    Terraform_Managed = "true"
    Environment       = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

# NAT Gateway - Usando apenas um para reduzir custos
resource "aws_nat_gateway" "ngw" {
  allocation_id     = aws_eip.ngw-ip.id
  subnet_id         = aws_subnet.subnet-public[keys(var.subnets_public)[0]].id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name              = var.ngw_name
    Terraform_Managed = "true"
    Environment       = var.environment
  }
}

###############
# Route Tables #
###############

# Route Table para Subnets Privadas - Uma única tabela para todas
resource "aws_route_table" "route-table-private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name              = join("-", [var.route_table_name, "private"])
    Terraform_Managed = "true"
    Environment       = var.environment
  }

  depends_on = [aws_nat_gateway.ngw]
}

# Associações das Route Tables Privadas
resource "aws_route_table_association" "route_table_subnet_association-private" {
  for_each = var.subnets_private

  subnet_id      = aws_subnet.subnet-private[each.key].id
  route_table_id = aws_route_table.route-table-private.id
}

# Route Table para Subnets Públicas
resource "aws_route_table" "route-table-public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name              = join("-", [var.route_table_name, "public"])
    Terraform_Managed = "true"
    Environment       = var.environment
  }
}

# Associações das Route Tables Públicas
resource "aws_route_table_association" "route_table_subnet_association-public" {
  for_each = var.subnets_public

  subnet_id      = aws_subnet.subnet-public[each.key].id
  route_table_id = aws_route_table.route-table-public.id
}
