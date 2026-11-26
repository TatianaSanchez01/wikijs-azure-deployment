output "vpc_id" {
  description = "Identificador de la VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Identificador de la subnet pública."
  value       = aws_subnet.public.id
}

output "web_security_group_id" {
  description = "Identificador del grupo de seguridad web."
  value       = aws_security_group.web.id
}