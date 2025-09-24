module network {
    source = "./modules/VPC_DecentMarten"
    project_id = var.project_id
    environment = var.environment
    enable_nat = var.enable_nat
    region = var.region
    vpcs = var.vpcs
    firewall_rules = var.firewall_rules
}


module "ngfw" {
    source = "./modules/VPC_PaloAlto"
    depends_on = [ module.network ]
    project_id = var.project_id
    management_subnet_id = var.management_subnet_id
    gke_subnet_id = var.gke_subnet_id
    environment = var.environment
    region = var.region
    palo_alto_image = var.palo_alto_image
}

module "GKE" {
  source = "./modules/GKE"
  project_id          = var.project_id
  environment         = var.environment
  region              = var.region
  region_zone         = var.region_zone
  node_count          = var.node_count
  nginx_replica_count = var.nginx_replica_count
}