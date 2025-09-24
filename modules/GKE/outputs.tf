output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "web_app_ip" {
  value = kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.ip
}