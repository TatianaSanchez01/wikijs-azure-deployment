variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para nombrar y etiquetar los recursos."
  type        = string
  default     = "wikijs-aws"
}

variable "vpc_cidr" {
  description = "Rango CIDR de la VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Rango CIDR de la subnet pública."
  type        = string
  default     = "10.20.1.0/24"
}

variable "app_allowed_cidrs" {
  description = "Rangos CIDR autorizados a acceder a Wiki.js por el puerto 3000."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Tamaño del volumen raíz cifrado en GB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "El volumen raíz debe tener al menos 8 GB."
  }
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL de Wiki.js."
  type        = string
  default     = "wikijs"
}

variable "db_username" {
  description = "Usuario de PostgreSQL."
  type        = string
  default     = "wikijs"
}

variable "db_password" {
  description = "Contraseña para PostgreSQL. Usa entre 16 y 64 caracteres alfanuméricos, guion o guion bajo."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{16,64}$", var.db_password))
    error_message = "La contraseña debe tener entre 16 y 64 caracteres y solo puede usar letras, números, guion y guion bajo."
  }
}

variable "my_ip" {
  description = "IP pública autorizada para conectarse por SSH."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "my_ip debe ser un CIDR IPv4 válido, por ejemplo 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Nombre de un par de claves EC2 existente en la región seleccionada."
  type        = string
}