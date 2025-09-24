output "vpc_networks" {
  value = { for k, v in google_compute_network.vpc : k => v.self_link }
}

output "subnetworks" {
  value = { for k, v in google_compute_subnetwork.subnet : k => v.self_link }
}

output "gke_subnet_name" {
  description = "Names of all subnets that have 'gke' in their name"
  value = {
    for k, v in google_compute_subnetwork.subnet :
    k => v.name
    if length(regexall("gke", lower(v.name))) > 0
  }
}

output "gke_subnet_self_link" {
  description = "Self links of all subnets that have 'gke' in their name"
  value = {
    for k, v in google_compute_subnetwork.subnet :
    k => v.self_link
    if length(regexall("gke", lower(v.name))) > 0
  }
}

output "firewall_rules" {
  description = "List of created firewall rules"
  value = [
    for rule in google_compute_firewall.rules : {
      name = rule.name
      id   = rule.id
    }
  ]
}

output "random_suffix" {
  description = "Random suffix used in resource names"
  value       = random_pet.network_suffix.id
}


