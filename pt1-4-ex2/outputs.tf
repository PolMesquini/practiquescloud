###############################################################################
# Exercici 2 - Outputs
###############################################################################

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "ID de cada subxarxa"
  value = {
    subnet_a = aws_subnet.subnet_a.id
    subnet_b = aws_subnet.subnet_b.id
    subnet_c = aws_subnet.subnet_c.id
  }
}

output "ami" {
  description = "AMI d'Amazon Linux 2023 utilitzada"
  value = {
    id   = data.aws_ami.amazon_linux_2023.id
    name = data.aws_ami.amazon_linux_2023.name
  }
}

output "instances" {
  description = "Instàncies EC2 desplegades amb la seva subxarxa i IPs"
  value = {
    for name, instance in aws_instance.web : name => {
      id                = instance.id
      subnet_id         = instance.subnet_id
      availability_zone = instance.availability_zone
      private_ip        = instance.private_ip
      public_ip         = instance.public_ip
    }
  }
}
