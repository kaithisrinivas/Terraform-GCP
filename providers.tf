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
  }
  backend "gcs" {
    bucket  = "srinivas-terraform-state"
    prefix = "dev"
  }
}

provider "google" {
  credentials = file(var.srinivas_credentials)
}