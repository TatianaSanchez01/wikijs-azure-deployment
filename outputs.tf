output "wikijs_url" {
  description = "URL HTTP de Wiki.js para demostración (sin TLS público)."
  value       = "http://${module.compute.public_ip}:3000"
}

output "instance_id" {
  value = module.compute.instance_id
}

output "public_ip" {
  value = module.compute.public_ip
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "rds_endpoint" {
  description = "Host privado de PostgreSQL administrado en RDS."
  value       = module.database.endpoint
}

output "cloudwatch_dashboard" {
  description = "Dashboard principal de monitoreo."
  value       = module.observability.dashboard_name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.application.name
}

output "ssh_connect_command" {
  value = "ssh -i <ruta-a-tu-archivo.pem> ec2-user@${module.compute.public_ip}"
}
