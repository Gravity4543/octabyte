# ties all the modules together

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  app_container_ports = [var.prod_port, var.staging_port]
  admin_cidr          = var.admin_cidr
}

module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_sg_id             = module.security.rds_sg_id
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  backup_retention_days = var.backup_retention_days
}

module "compute" {
  source = "./modules/compute"

  project_name             = var.project_name
  public_subnet_id         = module.vpc.public_subnet_ids[0]
  app_sg_id                = module.security.app_sg_id
  monitoring_sg_id         = module.security.monitoring_sg_id
  app_instance_type        = var.app_instance_type
  monitoring_instance_type = var.monitoring_instance_type
  db_secret_arn            = module.database.db_secret_arn
}

module "alb" {
  source = "./modules/alb"

  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.security.alb_sg_id
  app_instance_id     = module.compute.app_instance_id
  prod_port           = var.prod_port
  staging_port        = var.staging_port
  staging_host_header = var.staging_host_header
}
