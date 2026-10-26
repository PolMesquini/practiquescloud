###############################################################################
# Exercici 2 - Disseny i Desplegament de VPC, Subxarxes i EC2
#
# VPC personalitzada amb 3 subxarxes en us-east-1a i 6 instàncies EC2.
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

variable "vpc_cidr" {
  description = "Rang CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr ha de ser un rang CIDR IPv4 vàlid (per exemple, 10.0.0.0/16)."
  }
}

variable "subnet_a_cidr" {
  description = "CIDR del subnét A (10.0.32.0/25)"
  type        = string
  default     = "10.0.32.0/25"

  validation {
    condition     = can(cidrnetmask(var.subnet_a_cidr))
    error_message = "subnet_a_cidr ha de ser un rang CIDR IPv4 vàlid."
  }
}

variable "subnet_b_cidr" {
  description = "CIDR del subnét B (10.0.30.0/23)"
  type        = string
  default     = "10.0.30.0/23"

  validation {
    condition     = can(cidrnetmask(var.subnet_b_cidr))
    error_message = "subnet_b_cidr ha de ser un rang CIDR IPv4 vàlid."
  }
}

variable "subnet_c_cidr" {
  description = "CIDR del subnét C (10.0.33.0/28)"
  type        = string
  default     = "10.0.33.0/28"

  validation {
    condition     = can(cidrnetmask(var.subnet_c_cidr))
    error_message = "subnet_c_cidr ha de ser un rang CIDR IPv4 vàlid."
  }
}

variable "instance_type" {
  description = "Tipus d'instància EC2"
  type        = string
  default     = "t3.micro"
}

###############################################################################
# Dades: zones de disponibilitat i AMI d'Amazon Linux 2023
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# Obtenir l'ID de la zona us-east-1a
data "aws_availability_zone" "a1" {
  name = "us-east-1a"

}
