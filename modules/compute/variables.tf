variable "project_name" {
  description = "Prefijo usado en los nombres de los recursos."
  type        = string
}

variable "subnet_id" {
  description = "Identificador de la subnet pública."
  type        = string
}

variable "security_group_id" {
  description = "Identificador del grupo de seguridad."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
}

variable "root_volume_size" {
  description = "Tamaño del volumen raíz en GB."
  type        = number
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL."
  type        = string
}

variable "db_username" {
  description = "Usuario de PostgreSQL."
  type        = string
}

variable "db_password" {
  description = "Contraseña de PostgreSQL."
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Par de claves EC2 existente en la región."
  type        = string
}
