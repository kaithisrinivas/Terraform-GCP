variable "srinivas_credentials" {
  type = string
  description = "provide the credentials file path"
}
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
}

variable "vpcs" {
  description = "List of VPCs and their subnets"
  type = list(object({
    name    = string
    subnets = list(object({
      name                     = string
      ip_cidr_range            = string
      region                   = string
      private_ip_google_access = optional(bool, false)
      secondary_ranges         = optional(list(object({
        range_name    = string
        ip_cidr_range = string
      })), [])
    }))
  }))
}

variable "firewall_rules" {
  description = "List of firewall rules per VPC"
  type = list(object({
    name          = string
    direction     = string
    priority      = number
    allow         = list(object({
      protocol = string
      ports    = list(string)
    }))
    source_ranges = list(string)
    target_tags   = list(string)
    vpc_name      = string
  }))
}

variable "enable_nat" {
  description = "Enable Cloud NAT"
  type        = bool
  default     = false
}

variable "palo_alto_image" {
  description = "The image name for the Palo Alto VM-Series firewall"
  type        = string
  default     = "vmseries-byol-10-2-3" # Use an appropriate VM-Series image name
}
/*
variable "panos_hostname" {
  description = "The hostname or IP address of the Palo Alto firewall"
  type        = string
}

variable "panos_username" {
  description = "The username for the Palo Alto API"
  type        = string
}

variable "panos_password" {
  description = "The password for the Palo Alto API"
  type        = string
  sensitive   = true
}
*/

variable "management_subnet_id" {
    description = "Management subnet"
    type = string
}

variable "gke_subnet_id" {
    description = "The GKE subnet ID"
    type = string
}

variable "region_zone" {
  description = "The GCP zone within the region"
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the GKE cluster"
  type        = number
}

variable "nginx_replica_count" {
  description = "The number of NGINX replicas to deploy"
  type        = number
}
