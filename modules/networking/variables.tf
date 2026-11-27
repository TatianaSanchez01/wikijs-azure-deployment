variable "project_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr" {
  type = string
}
variable "private_subnet_cidrs" {
  type = list(string)
}
variable "app_allowed_cidrs" {
  type = list(string)
}
variable "my_ip" {
  type = string
}
