module "compute" {
  source       = "./modules/compute"
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  network_name = var.network_name
  subnet_name  = module.network.subnet_name
}

module "network" {
  source            = "./modules/network"
  project_id        = var.project_id
  region            = var.region
  network_name      = var.network_name
  subnet_cidr       = var.subnet_cidr
  allowed_ip_ranges = var.allowed_ip_ranges
  instance_group    = module.compute.instance_group
}
