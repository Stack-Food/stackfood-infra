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

# Subnets Privadas
resource "aws_subnet" "subnet-private" {
  for_each = var.subnets_private

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = try(each.value.availability_zone, data.aws_availability_zones.availability_zones.names[index(keys(var.subnets_private), each.key) % length(data.aws_availability_zones.availability_zones.names)])
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

# Elastic IPs para NAT Gateways
resource "aws_eip" "ngw-ip" {
  for_each = var.subnets_public
  domain   = "vpc"

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name              = join("-", [var.vpc_name, "eip", each.key])
    Terraform_Managed = "true"
    Environment       = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

# NAT Gateways
resource "aws_nat_gateway" "ngw" {
  for_each = var.subnets_public

  allocation_id     = aws_eip.ngw-ip[each.key].id
  subnet_id         = aws_subnet.subnet-public[each.key].id
  connectivity_type = "public"

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name              = join("-", [var.ngw_name, each.key])
    Terraform_Managed = "true"
    Environment       = var.environment
  }
}

###############
# Route Tables #
###############

# Locals para mapear subnets privadas com NAT Gateways
locals {
  # Cria um mapeamento baseado na AZ ou índice para garantir consistência
  private_nat_mapping = {
    for private_key, private_subnet in var.subnets_private :
    private_key => {
      nat_gateway_key = try(
        # Tenta encontrar um NAT Gateway na mesma AZ
        [for public_key, public_subnet in var.subnets_public :
          public_key if try(public_subnet.availability_zone, "") == try(private_subnet.availability_zone, "")
        ][0],
        # Se não encontrar, usa o primeiro NAT Gateway disponível
        keys(var.subnets_public)[index(keys(var.subnets_private), private_key) % length(keys(var.subnets_public))]
      )
    }
  }
}

# Route Tables para Subnets Privadas
resource "aws_route_table" "route-table-private" {
  for_each = var.subnets_private

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[local.private_nat_mapping[each.key].nat_gateway_key].id
  }

  tags = {
    Name              = join("-", [var.route_table_name, "private", each.key])
    Terraform_Managed = "true"
    Environment       = var.environment
  }

  depends_on = [aws_nat_gateway.ngw]
}

# Associações das Route Tables Privadas
resource "aws_route_table_association" "route_table_subnet_association-private" {
  for_each = var.subnets_private

  subnet_id      = aws_subnet.subnet-private[each.key].id
  route_table_id = aws_route_table.route-table-private[each.key].id
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
