###############################################################################
# Exercici 1 - Primeres instàncies EC2 amb Terraform
#
# Desplega 2 instàncies EC2 t3.micro amb Amazon Linux 2023 a la regió us-east-1,
# dins d'una VPC pròpia amb dues subxarxes públiques, Internet Gateway i un
# Security Group que permet HTTP (port 80).
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
}

###############################################################################
# Variables
###############################################################################

variable "aws_region" {
  description = "Regió AWS on es despleguen els recursos"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Aquest exercici s'ha de desplegar a la regió us-east-1."
  }
}

variable "project_name" {
  description = "Prefix utilitzat per anomenar i etiquetar els recursos"
  type        = string
  default     = "pt1-4-ex1"
}

variable "instance_type" {
  description = "Tipus d'instància EC2"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "Rang CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr ha de ser un rang CIDR IPv4 vàlid (per exemple, 10.0.0.0/16)."
  }
}

###############################################################################
# Dades: zones de disponibilitat i AMI d'Amazon Linux 2023
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# Es busca sempre la versió més recent d'Amazon Linux 2023 (x86_64) en lloc
# de fixar un AMI ID que quedaria obsolet amb el temps.
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
# Xarxa: VPC, subxarxes públiques, Internet Gateway i taula de rutes
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Dues subxarxes públiques, una per zona de disponibilitat.
# La primera és 10.0.1.0/24 i la segona 10.0.2.0/24.
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
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

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Security Group: HTTP des d'Internet i sortida lliure
###############################################################################

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Permet HTTP des de Internet i tot el transit de sortida"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP des de Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Tot el transit de sortida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

###############################################################################
# Instàncies EC2
###############################################################################

resource "aws_instance" "web" {
  count = 2

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  # Enduriment del servei de metadades: només IMDSv2.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Apache serveix una pàgina que identifica la instància. Serveix per
  # comprovar que les dues EC2 són accessibles per HTTP.
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    dnf install -y httpd
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html lang="ca">
      <head>
        <meta charset="utf-8">
        <title>Exercici 1 - Terraform</title>
        <style>
          body { font-family: system-ui, sans-serif; margin: 3rem; color: #232f3e; }
          h1 { color: #ff9900; }
          code { background: #f2f3f3; padding: .2rem .4rem; border-radius: 4px; }
        </style>
      </head>
      <body>
        <h1>Hola des de $(hostname)</h1>
        <p>Inst&agrave;ncia EC2 desplegada amb <strong>Terraform</strong>.</p>
        <p>Sistema operatiu: <strong>Amazon Linux 2023</strong> &middot; Tipus: <strong>t3.micro</strong></p>
        <p>Regi&oacute;: <code>us-east-1</code></p>
      </body>
    </html>
    HTML

    systemctl enable --now httpd
  EOT

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}

###############################################################################
# Outputs
###############################################################################

output "web_instances" {
  description = "Identificador, IP pública, DNS i URL de cada instància"
  value = {
    for index, instance in aws_instance.web :
    "web-${index + 1}" => {
      id                = instance.id
      public_ip         = instance.public_ip
      public_dns        = instance.public_dns
      url               = "http://${instance.public_ip}/"
      availability_zone = instance.availability_zone
      subnet_id         = instance.subnet_id
    }
  }
}

output "ami" {
  description = "AMI d'Amazon Linux 2023 utilitzada"
  value = {
    id   = data.aws_ami.amazon_linux_2023.id
    name = data.aws_ami.amazon_linux_2023.name
  }
}

output "network" {
  description = "Identificadors de la xarxa creada"
  value = {
    vpc_id            = aws_vpc.main.id
    public_subnet_ids = aws_subnet.public[*].id
    security_group_id = aws_security_group.web.id
  }
}
