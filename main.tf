module network {
    source = "./modules/VPC"
    project_id = var.project_id
    environment = var.environment
    enable_nat = var.enable_nat
    region = var.region
    subnets = var.subnets
    firewall_rules = var.firewall_rules
}