output "wikijs_url" {
  description = "URL para abrir Wiki.js."
  value       = "http://${module.compute.public_ip}:3000"
}

output "instance_id" {
  description = "Identificador de la instancia EC2."
  value       = module.compute.instance_id
}

output "public_ip" {
  description = "Dirección IP pública de la instancia."
  value       = module.compute.public_ip
}

output "vpc_id" {
  description = "Identificador de la VPC creada."
  value       = module.networking.vpc_id
}

output "ssh_connect_command" {
  description = "Comando para conectarse a la instancia por SSH."
  value       = "ssh -i <ruta-a-tu-archivo.pem> ec2-user@${module.compute.public_ip}"
}