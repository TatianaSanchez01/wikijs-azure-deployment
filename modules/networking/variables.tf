variable "project_name" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR de la VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "Rango CIDR de la subnet pública."
  type        = string
}

variable "app_allowed_cidrs" {
  description = "Rangos CIDR autorizados a acceder a la aplicación."
  type        = list(string)
}

variable "my_ip" {
  description = "IP pública autorizada para conectarse por SSH."
  type        = string
}