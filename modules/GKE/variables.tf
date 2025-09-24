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

