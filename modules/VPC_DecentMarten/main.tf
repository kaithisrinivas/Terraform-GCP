# Random pet name for unique resource naming
resource "random_pet" "network_suffix" {
  length = 2
  keepers = {
    environment = var.environment
    project_id  = var.project_id
  }
}

locals {
  network_name = "${var.environment}-vpc-${random_pet.network_suffix.id}"
  common_tags = {
    Environment  = var.environment
    ManagedBy    = "terraform"
    NetworkName  = local.network_name
  }
  # Create a map for easy lookup of subnet CIDR ranges
  subnet_cidrs = {
    for subnet in var.subnets : subnet.name => subnet.ip_cidr_range
  }
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = local.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Shared VPC network for ${var.environment} environment"
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
  }

  name                     = "${local.network_name}-${each.value.name}"
  project                  = var.project_id
  region                   = each.value.region != null ? each.value.region : var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  depends_on = [google_compute_network.main]
}

# Cloud Router for NAT (kept as it handles NAT for internal VMs, but not
# traffic routing for the firewall)
resource "google_compute_router" "router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${local.network_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT (kept for other non-firewalled VMs)
resource "google_compute_router_nat" "nat" {
  count   = var.enable_nat ? 1 : 0
  name    = "${local.network_name}-nat"
  project = var.project_id
  router  = google_compute_router.router[0].name
  region  = google_compute_router.router[0].region

  nat_ip_allocate_option       = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = {
    for rule in var.firewall_rules : rule.name => rule
  }

  name    = "${local.network_name}-${each.value.name}"
  project = var.project_id
  network = google_compute_network.main.name

  direction = each.value.direction
  priority  = each.value.priority

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  source_ranges           = each.value.source_ranges
  destination_ranges      = each.value.destination_ranges
  source_tags             = each.value.source_tags
  target_tags             = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts
}

# Default firewall rules for common use cases
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    for subnet in var.subnets : subnet.ip_cidr_range
  ]

  description = "Allow internal communication within VPC"
}

# Default firewall rules from your original configuration are handled by the
# explicit PAN-OS policies and a final deny-all rule.
# The IAP rule `allow_ssh` is kept as it is a GCP-level firewall rule that works
# on the compute instance itself, and doesn't need to pass through the Palo Alto firewall.
resource "google_compute_firewall" "allow_ssh" {
  name    = "${local.network_name}-allow-ssh-iap"
  project = var.project_id
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["ssh"]

  description = "Allow SSH via Identity-Aware Proxy"
}