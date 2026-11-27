output "endpoint" {
  value = aws_db_instance.postgres.address
}
output "port" {
  value = aws_db_instance.postgres.port
}
output "identifier" {
  value = aws_db_instance.postgres.identifier
}
