module "tagging" {
  source      = "./modules/tagging"
  environment = var.environment
  owner       = var.owner
  project     = var.project
  cost_center = var.cost_center
}

module "budgeting" {
  source       = "./modules/budgeting"
  alert_emails = var.alert_emails
}

module "governance_security" {
  source = "./modules/governance_security"
}

module "networking" {
  source = "./modules/networking"
}

module "lambdas" {
  source       = "./modules/lambdas"
  vpc_id       = module.networking.vpc_id
  alert_emails = var.alert_emails
}

module "storage_certs" {
  source             = "./modules/storage_certs"
  private_subnet_ids = module.networking.private_subnet_ids
}