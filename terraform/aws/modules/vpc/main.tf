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

resource "aws_vpc_ipv4_cidr_block_association" "vpc-cidr" {
  for_each = {
    for vpc_cidr_block in var.vpc_cidr_blocks :
    index(var.vpc_cidr_blocks, vpc_cidr_block) => vpc_cidr_block
    if index(var.vpc_cidr_blocks, vpc_cidr_block) != 0
  }

  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value
}

# Subnet(s)
resource "aws_subnet" "subnet-private" {
  for_each = var.subnets_private

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = try(each.value.availability_zone, data.aws_availability_zones.availability_zones.names[0])
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name                              = join("-", [var.vpc_name, "private", each.key])
      Terraform_Managed                 = "true"
      Environment                       = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    },
    var.tags
  )
}

resource "aws_subnet" "subnet-public" {
  for_each = var.subnets_public

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = try(each.value.availability_zone, data.aws_availability_zones.availability_zones.names[0])
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                     = join("-", [var.vpc_name, "public", each.key])
      Terraform_Managed        = "true"
      Environment              = var.environment
      "kubernetes.io/role/elb" = "1"
    },
    var.tags
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name              = var.igw_name
    Terraform_Managed = "true"
  }
}

# NAT Gateway
resource "aws_eip" "ngw-ip" {
  for_each = var.subnets_public
  domain   = "vpc"

  tags = {
    Name              = join("-", [var.vpc_name, "eip", each.key])
    Terraform_Managed = "true"
    Environment       = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_nat_gateway" "ngw" {
  for_each = var.subnets_public

  allocation_id     = aws_eip.ngw-ip[each.key].id
  subnet_id         = aws_subnet.subnet-public[each.key].id
  connectivity_type = "public"

  tags = {
    Name              = var.ngw_name
    Terraform_Managed = "true"
  }

}


###############
# Route Table #
###############

# Route Table
resource "aws_route_table" "route-table-private" {
  for_each = var.subnets_private

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[keys(var.subnets_public)[index(keys(var.subnets_private), each.key)]].id
  }

  tags = {
    Name              = join("-", [var.route_table_name, "private", each.key])
    Terraform_Managed = "true"
  }
}

resource "aws_route_table_association" "route_table_subnet_association-private" {
  for_each = var.subnets_private

  subnet_id      = aws_subnet.subnet-private[each.key].id
  route_table_id = aws_route_table.route-table-private[each.key].id
}

resource "aws_route_table" "route-table-public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name              = join("-", [var.route_table_name, "public"])
    Terraform_Managed = "true"
  }
}

resource "aws_route_table_association" "route_table_subnet_association-public" {
  for_each = var.subnets_public

  subnet_id      = aws_subnet.subnet-public[each.key].id
  route_table_id = aws_route_table.route-table-public.id
}
