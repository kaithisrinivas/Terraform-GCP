resource "random_pet" "network_suffix" {
  length = 2
  keepers = {
    environment = var.environment
    project_id  = var.project_id
  }
}

/*
locals {
  common_tags = {
    Environment  = var.environment
    ManagedBy    = "terraform"
    NetworkName  = local.network_name
  }
  # Define the security policies for the Palo Alto firewall
  # These will be used to create individual `panos_security_policy_rule` resources
  panos_rules = {
    "allow-gke-webhooks" = {
      source_zones          = ["trust-zone"]
      destination_zones     = ["trust-zone"]
      source_addresses      = [local.subnet_cidrs["gke"]]
      destination_addresses = [local.subnet_cidrs["gke"]]
      applications          = ["web-browsing", "ssl"]
      services              = ["tcp-8443", "tcp-9443", "tcp-15017"]
      action                = "allow"
      log_end              = true
    },
    "allow-web-traffic" = {
      source_zones          = ["untrust-zone"]
      destination_zones     = ["trust-zone"]
      source_addresses      = ["any"]
      destination_addresses = [local.subnet_cidrs["web"]]
      applications          = ["any"]
      services              = ["service-http", "service-https"]
      action                = "allow"
      log_end              = true
    },
    "allow-db-access" = {
      source_zones          = ["trust-zone"]
      destination_zones     = ["trust-zone"]
      source_addresses      = [local.subnet_cidrs["web"], local.subnet_cidrs["gke"]]
      destination_addresses = [local.subnet_cidrs["db"]]
      applications          = ["any"]
      services              = ["tcp-5432", "tcp-3306"]
      action                = "allow"
      log_end              = true
    },
    "allow-mgmt-ssh" = {
      source_zones          = ["trust-zone"]
      destination_zones     = ["trust-zone"]
      source_addresses      = [local.subnet_cidrs["mgmt"]]
      destination_addresses = ["any"]
      applications          = ["ssh"]
      services              = ["any"]
      action                = "allow"
      log_end              = true
    },
    "deny-all-unmatched" = {
      source_zones          = ["any"]
      destination_zones     = ["any"]
      source_addresses      = ["any"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      action                = "deny"
      log_end              = true
    }
  }
}
*/

################################################################################
# Palo Alto VM-Series Deployment
# We deploy a single VM-Series firewall and create a routing policy
# to send all egress traffic from your subnets to it.
################################################################################

# Assuming you already created the subnet using google_compute_subnetwork
data "google_compute_subnetwork" "mgmt" {
  name   = "${var.environment}-vpc-${var.subnets[3].name}" # Example: dev-vpc-mgmt
  region = var.region
}

# Deploy the Palo Alto VM-Series firewall instance
resource "google_compute_instance" "palo_alto_vm" {
  name         = "palo-alto-firewall-${random_pet.network_suffix.id}"
  machine_type = "n2-standard-2" # Use an appropriate machine type for your license
  project      = var.project_id
  zone       = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = var.palo_alto_image
    }
  }

  # This configuration assumes a two-interface setup:
  # eth0 is the management interface (not routed here, configured with a public IP or IAP)
  # eth1 is the trust/untrust interface, using a single virtual wire.
  # Management interface on the `mgmt` subnet
  network_interface {
    #subnetwork = var.management_subnet_id
    subnetwork = data.google_compute_subnetwork.mgmt.self_link
    network_ip = "10.2.48.5" # A static IP within your mgmt subnet
    access_config {}
    subnetwork_project = var.project_id
  }

  # Data plane interface on the `gke` subnet
  #network_interface {
  #  subnetwork = var.gke_subnet_id # or another dedicated subnet
  #  network_ip = "10.2.0.5" # Static IP within the gke subnet
  #  subnetwork_project = var.project_id
  #}

  can_ip_forward = true # IMPORTANT: Required for a firewall
  tags           = ["ssh"]
}

 
# Create a route to send all egress traffic from your subnets to the firewall.
# This assumes the firewall is a next-hop instance.
# A more advanced setup might use a virtual wire. This is a simplified model.
/*
resource "google_compute_route" "egress_to_palo_alto" {
  name             = "${local.network_name}-egress-to-palo-alto"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.main.id
  next_hop_instance = google_compute_instance.palo_alto_vm.name
  next_hop_instance_zone = google_compute_instance.palo_alto_vm.zone
  priority         = 800 # A lower priority than the IAP rule
}
*/
################################################################################
# Palo Alto (PAN-OS) Configuration
# These resources configure the security policies on the VM-Series firewall.
# They replace the `google_compute_firewall` rules.
################################################################################

# Define the Virtual System (vsys) for the firewall.
# Define the Virtual System (vsys) for the firewall.
# Create the data plane interface on the Palo Alto firewall
/*
resource "panos_ethernet_interface" "data_plane" {
  location = {
    ngfw = {
      ngfw_device = "paloalto-vmseries"
    }
  }
  name     = "ethernet1/2" # Corresponds to the second network interface on the GCP instance
  layer3 = {} # The interface is configured for Layer 3 (routed) mode
}

# Create security zones on the Palo Alto firewall
resource "panos_zone" "trust" {
  depends_on = [ panos_ethernet_interface.data_plane ]
  location = {
    template = {
      name = panos_template.example.name
      vsys = "vsys1"
    }
  }
  name     = "trust-zone"
  network = {
    layer3 = [panos_ethernet_interface.data_plane.name]
  }
}

resource "panos_zone" "untrust" {
  depends_on = [ panos_ethernet_interface.data_plane ]
  location = {
    template = {
      name = panos_template.example.name
      vsys = "vsys1"
    }
  }
  name     = "untrust-zone"
  # This zone does not have an explicit interface, representing the internet.
}

resource "panos_template" "example" {
  location = { panorama = {} }

  name = "example-template"
}

# The panos provider will automatically create the necessary virtual routers and
# interfaces based on the VM-Series' network interfaces.
# We will create security policies based on the original `firewall_rules`.

# Configure the security policy rules. These replace your `google_compute_firewall` rules.
# We're using a `for_each` loop to create each rule individually, and setting its
# position to `pre-rulebase`.
resource "panos_security_policy_rules" "security_policy" {
  for_each = local.panos_rules
  rules = [ {
    name                  = each.key
    action                = each.value.action
    log_end               = each.value.log_end
    source_zones          = each.value.source_zones
    source_addresses      = each.value.source_addresses
    destination_zones     = each.value.destination_zones
    destination_addresses = each.value.destination_addresses
    applications          = each.value.applications
    services              = each.value.services
  } ]
  # These are the attributes you were missing!
  location = {
    vsys = {
      ngfw_device = "paloalto-vmseries"
    }
  }
  position = {
    where = "first"
  }
}
*/