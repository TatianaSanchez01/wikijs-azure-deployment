variable "aws_region" {
  description = "Región de AWS para la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para identificar recursos."
  type        = string
  default     = "wikijs-aws"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR de la subred pública para EC2."
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "Dos subredes privadas en zonas diferentes para RDS."
  type        = list(string)
  default     = ["10.20.2.0/24", "10.20.3.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Debes proporcionar exactamente dos CIDR privados."
  }
}

variable "app_allowed_cidrs" {
  description = "CIDR permitidos al puerto HTTP 3000 de Wiki.js."
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Tamaño del volumen EBS de EC2 en GB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Se requieren al menos 8 GB."
  }
}

variable "db_name" {
  description = "Nombre de la base PostgreSQL de Wiki.js."
  type        = string
  default     = "wikijs"
}

variable "db_username" {
  description = "Usuario administrador de RDS (evita nombres reservados)."
  type        = string
  default     = "wikijs"
}

variable "db_instance_class" {
  description = "Clase de RDS PostgreSQL."
  type        = string
  default     = "db.t4g.micro"
}

variable "alert_email" {
  description = "Correo para alarmas SNS; dejar vacío si no se requieren notificaciones."
  type        = string
  default     = ""
}

variable "my_ip" {
  description = "CIDR IPv4 autorizado para SSH (ejemplo 203.0.113.10/32)."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "Usa un CIDR IPv4 válido."
  }
}

variable "key_name" {
  description = "Nombre de un par de claves EC2 existente."
  type        = string
}

variable "db_password" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{16,64}$", var.db_password))
    error_message = "Usa 16 a 64 caracteres alfanuméricos, guion o guion bajo."
  }
}

variable "grafana_password" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{16,64}$", var.grafana_password))
    error_message = "Usa 16 a 64 caracteres alfanuméricos, guion o guion bajo."
  }
}
