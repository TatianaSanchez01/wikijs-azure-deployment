output "instance_id" {
  description = "Identificador de la instancia EC2."
  value       = aws_instance.wikijs.id
}

output "public_ip" {
  description = "Dirección IP pública de la instancia."
  value       = aws_instance.wikijs.public_ip
}