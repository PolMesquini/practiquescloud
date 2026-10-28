###############################################################################
# Exercici 2 - Variables del desplegament
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

variable "availability_zone" {
  description = "Zona de disponibilitat on s'ubiquen les tres subxarxes"
  type        = string
  default     = "us-east-1a"

  validation {
    condition     = startswith(var.availability_zone, var.aws_region)
    error_message = "availability_zone ha de pertànyer a la regió indicada a aws_region."
  }
}

variable "project_name" {
  description = "Prefix utilitzat per anomenar i etiquetar els recursos"
  type        = string
  default     = "pt1-4-ex2"
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
  description = "CIDR de la subxarxa A"
  type        = string
  default     = "10.0.32.0/25"

  validation {
    condition     = can(cidrnetmask(var.subnet_a_cidr))
    error_message = "subnet_a_cidr ha de ser un rang CIDR IPv4 vàlid."
  }
}

variable "subnet_b_cidr" {
  description = "CIDR de la subxarxa B"
  type        = string
  default     = "10.0.30.0/23"

  validation {
    condition     = can(cidrnetmask(var.subnet_b_cidr))
    error_message = "subnet_b_cidr ha de ser un rang CIDR IPv4 vàlid."
  }
}

variable "subnet_c_cidr" {
  description = "CIDR de la subxarxa C"
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

  validation {
    condition     = var.instance_type == "t3.micro"
    error_message = "Aquest exercici utilitza instàncies t3.micro."
  }
}
