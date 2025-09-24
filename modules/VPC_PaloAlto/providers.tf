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
    #panos = {
    #  source  = "PaloAltoNetworks/panos"
    #  version = "~> 2.0.0"
    #}
  }
}