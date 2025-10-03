output "service_endpoint" {
  description = "Endpoint público do LoadBalancer"
  value = (
    try(kubernetes_service.app.status[0].load_balancer[0].ingress[0].hostname, null) != null ?
    kubernetes_service.app.status[0].load_balancer[0].ingress[0].hostname :
    kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip
  )
}

output "service_name" {
  description = "Nome do service Kubernetes"
  value       = kubernetes_service.app.metadata[0].name
}

output "deployment_name" {
  description = "Nome do deployment Kubernetes"
  value       = kubernetes_deployment.app.metadata[0].name
}