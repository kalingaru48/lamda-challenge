# VPC Resource
resource "aws_vpc" "this" {
  cidr_block                           = var.vpc_cidr
  assign_generated_ipv6_cidr_block     = true
  enable_dns_support                   = true
  enable_dns_hostnames                 = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"

  tags = {
    Name = "${var.project_name}-vpc-001"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-vlan-${format("%03d", index(keys(var.public_subnets), each.key) + 1)}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.project_name}-pvt-vlan-${format("%03d", index(keys(var.private_subnets), each.key) + 1)}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-pub-igw-001"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-pub-rt-001"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway and EIP
resource "aws_eip" "this" {
  for_each = var.public_subnets
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-pub-eip-${format("%03d", index(keys(var.public_subnets), each.key) + 1)}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = var.public_subnets

  allocation_id = aws_eip.this[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project_name}-pub-natgw-${format("%03d", index(keys(var.public_subnets), each.key) + 1)}"
  }
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-int-rt-${format("%03d", index(keys(var.private_subnets), each.key) + 1)}"
  }
}

resource "aws_route" "route_internet_to_natgw" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[keys(var.public_subnets)[0]].id # Uses first NAT Gateway
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}