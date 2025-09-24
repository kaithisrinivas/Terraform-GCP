variable "project_id" {
  description = "project_id"
  type = string
}
variable "enable_nat" {
  description = "Enable Cloud NAT for private subnets"
  type        = bool
  default     = true
}
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}


variable "palo_alto_image" {
  description = "The image name for the Palo Alto VM-Series firewall"
  type        = string
  #default     = "vmseries-byol-10-2-3" # Use an appropriate VM-Series image name
}

variable "region" {
    description = "The compute region"
    type = string
  
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