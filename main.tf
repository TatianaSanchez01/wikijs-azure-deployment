module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  app_allowed_cidrs  = var.app_allowed_cidrs
  my_ip              = var.my_ip
}

module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.web_security_group_id

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  key_name = var.key_name
}
