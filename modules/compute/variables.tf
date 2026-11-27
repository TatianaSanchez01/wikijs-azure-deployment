variable "project_name" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "security_group_id" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "root_volume_size" {
  type = number
}
variable "key_name" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_username" {
  type = string
}
variable "db_host" {
  type = string
}
variable "db_port" {
  type = number
}
variable "db_secret_arn" {
  type = string
}
variable "log_group_name" {
  type = string
}
