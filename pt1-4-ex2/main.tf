###############################################################################
# Exercici 2 - Disseny i desplegament de VPC, subxarxes i instàncies EC2
#
# Crea una VPC 10.0.0.0/16 amb tres subxarxes a us-east-1a i desplega dues
# instàncies EC2 t3.micro (Amazon Linux 2023) a cadascuna, fins a un total
# de sis instàncies.
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}

###############################################################################
# AMI d'Amazon Linux 2023
###############################################################################

# Es consulta sempre la versió més recent d'Amazon Linux 2023 (x86_64) per no
# fixar un AMI ID que quedaria obsolet.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

###############################################################################
# Internet Gateway i taula de rutes pública
###############################################################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

###############################################################################
# Tres subxarxes a us-east-1a
###############################################################################

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-b"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_c_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-c"
  }
}

resource "aws_route_table_association" "subnet_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_c" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Security Group de les instàncies
###############################################################################

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Grup de seguretat de les instancies EC2"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Tot el transit de sortida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

###############################################################################
# Sis instàncies EC2 (dues per subxarxa)
###############################################################################

locals {
  instances = {
    "subnet-a-1" = aws_subnet.subnet_a.id
    "subnet-a-2" = aws_subnet.subnet_a.id
    "subnet-b-1" = aws_subnet.subnet_b.id
    "subnet-b-2" = aws_subnet.subnet_b.id
    "subnet-c-1" = aws_subnet.subnet_c.id
    "subnet-c-2" = aws_subnet.subnet_c.id
  }
}

resource "aws_instance" "web" {
  for_each = local.instances

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = each.value
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  # El servei de metadades només accepta tokens IMDSv2.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}
