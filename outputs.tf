output "service_name" {
  value = kubernetes_service.app.metadata[0].name
}

output "service_hostname" {
  value = kubernetes_service.app.status[0].load_balancer[0].hostname
}