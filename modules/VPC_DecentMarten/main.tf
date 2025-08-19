# Random pet name for unique resource naming
resource "random_pet" "network_suffix" {
  length = 2
  keepers = {
    environment = var.environment
    project_id  = var.project_id
  }
}
# --- Create VPCs ---
resource "random_id" "vpc_suffix" {
  for_each    = { for vpc in var.vpcs : vpc.name => vpc }
  byte_length = 2
}

# --- VPC Networks ---
resource "google_compute_network" "vpc" {
  for_each = { for vpc in var.vpcs : vpc.name => vpc }
  project                 = var.project_id
  name                    = "${var.environment}-vpc-${each.value.name}"
  auto_create_subnetworks = false
}

# --- Subnets ---
resource "google_compute_subnetwork" "subnet" {
  for_each = {
    for entry in flatten([
      for vpc in var.vpcs : [
        for subnet in vpc.subnets : {
          key                      = "${vpc.name}-${subnet.name}"
          vpc_name                 = vpc.name
          subnet_name              = subnet.name
          ip_cidr_range            = subnet.ip_cidr_range
          private_ip_google_access = lookup(subnet, "private_ip_google_access", false)
          secondary_ranges         = lookup(subnet, "secondary_ranges", [])
        }
      ]
    ]) : entry.key => entry
  }
  project                  = var.project_id
  name                     = "${var.environment}-subnet-${each.value.subnet_name}"
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = var.region
  network                  = google_compute_network.vpc[each.value.vpc_name].id
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

# --- Cloud Router for each VPC ---
resource "google_compute_router" "router" {
  for_each = google_compute_network.vpc

  project   = var.project_id
  name      = "${var.environment}-router-${each.key}"
  network   = each.value.id
  region    = var.region
}

# --- Cloud NAT for each VPC ---
resource "google_compute_router_nat" "nat" {
  for_each = google_compute_router.router

  project                            = var.project_id
  name                               = "${var.environment}-nat-${each.key}"
  router                             = each.value.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}

# Create Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  project   = var.project_id
  name      = each.value.name
  network   = google_compute_network.vpc["evolving-gecko-mgmt"].self_link
  direction = each.value.direction
  priority  = each.value.priority

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags
}
