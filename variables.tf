variable "srinivas_credentials" {
  type = string
  description = "provide the credentials file path"
}
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                     = string
    ip_cidr_range           = string
    region                  = optional(string)
    private_ip_google_access = optional(bool, true)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    name      = string
    direction = string
    priority  = optional(number, 1000)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    source_ranges      = optional(list(string))
    destination_ranges = optional(list(string))
    source_tags        = optional(list(string))
    target_tags        = optional(list(string))
    target_service_accounts = optional(list(string))
  }))
  default = []
}

variable "enable_nat" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = true
}