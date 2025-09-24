terraform {
  required_version = ">=1.12.2"
  required_providers {
    google = {
        source = "hashicorp/google"
        version = "~> 6.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
    }
  }
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}