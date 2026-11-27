module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs  = var.private_subnet_cidrs
  app_allowed_cidrs    = var.app_allowed_cidrs
  my_ip                = var.my_ip
}

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  app_security_group_id = module.networking.web_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_instance_class     = var.db_instance_class
  db_password           = var.db_password
}

module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.web_security_group_id
  instance_type     = var.instance_type
  root_volume_size  = var.root_volume_size
  key_name          = var.key_name

  db_name          = var.db_name
  db_username      = var.db_username
  db_host          = module.database.endpoint
  db_port          = module.database.port
  db_password      = var.db_password
  grafana_password = var.grafana_password
}

module "observability" {
  source = "./modules/observability"

  project_name          = var.project_name
  aws_region            = var.aws_region
  ec2_instance_id       = module.compute.instance_id
  rds_identifier        = module.database.identifier
  alert_email           = var.alert_email
}
