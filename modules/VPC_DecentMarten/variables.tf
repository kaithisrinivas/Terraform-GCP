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