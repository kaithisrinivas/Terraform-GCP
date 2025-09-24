# Enable necessary Google Cloud APIs
resource "google_project_service" "gke_api" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = false
}

# Create a GKE cluster
resource "google_container_cluster" "primary" {
  name                     = "terraform-gke-cluster-${random_string.suffix.result}"
  location                 = var.region
  node_locations           = [var.region_zone]
  remove_default_node_pool = true
  initial_node_count       = 1
  project                  = var.project_id

  network = "dev-vpc-evolving-gecko-gke"
  subnetwork = "dev-subnet-gke"
  depends_on = [
    google_project_service.gke_api
  ]

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Create a node pool for the GKE cluster
resource "google_container_node_pool" "primary_nodes" {
  depends_on = [ google_container_cluster.primary ]
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  project    = var.project_id

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["http"]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Deploy a Kubernetes Deployment for the web app
resource "kubernetes_deployment" "nginx" {
  depends_on = [ google_container_node_pool.primary_nodes ]
  metadata {
    name = "nginx-deployment"
    labels = {
      App = "nginx"
    }
  }
  spec {
    replicas = var.nginx_replica_count
    selector {
      match_labels = {
        App = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          App = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:1.21.6"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Expose the Deployment with a LoadBalancer Service
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-service"
  }
  spec {
    selector = {
      App = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

# Data source for dynamic provider configuration
data "google_client_config" "current" {}

# Generate a random string for unique resource names
resource "random_string" "suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# This Ingress resource creates the HTTP Load Balancer.
# It routes all incoming traffic on port 80 to the internal Nginx service.
resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name = "nginx-http-ingress"
  }
  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = kubernetes_service.nginx.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
