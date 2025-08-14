output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnets" {
  description = "Map of subnet names to their details"
  value = {
    for k, subnet in google_compute_subnetwork.subnets : k => {
      name              = subnet.name
      id                = subnet.id
      self_link         = subnet.self_link
      ip_cidr_range     = subnet.ip_cidr_range
      region            = subnet.region
      secondary_ranges  = subnet.secondary_ip_range
    }
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

output "gke_subnet_name" {
  description = "Name of the GKE subnet (assumes first subnet is for GKE)"
  value       = length(var.subnets) > 0 ? google_compute_subnetwork.subnets[var.subnets[0].name].name : null
}

output "gke_subnet_self_link" {
  description = "Self link of the GKE subnet"
  value       = length(var.subnets) > 0 ? google_compute_subnetwork.subnets[var.subnets[0].name].self_link : null
}
