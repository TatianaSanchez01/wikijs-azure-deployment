output "endpoint" {
  value = aws_db_instance.postgres.address
}
output "port" {
  value = aws_db_instance.postgres.port
}
output "identifier" {
  value = aws_db_instance.postgres.identifier
}
output "master_user_secret_arn" {
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  description = "ARN de la contraseña que RDS gestiona en Secrets Manager."
}
