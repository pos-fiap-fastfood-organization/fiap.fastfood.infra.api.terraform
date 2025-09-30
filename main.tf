resource "kubernetes_config_map" "app_config" {
  metadata {
    name = "${var.app_name}-config"
  }
  data = {
    MERCADOPAGO_API_URL   = "https://api.mercadopago.com"
    ASPNETCORE_ENVIRONMENT = "Development"
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name = "${var.app_name}-secret"
  }
  data = {
    MERCADOPAGO_API_TOKEN  = var.mercadopago_api_token
    StringConnectionMongo  = var.mongo_connection_string
  }
  type = "Opaque"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = var.app_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = var.container_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name = "MERCADOPAGO_API_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "MERCADOPAGO_API_TOKEN"
              }
            }
          }

          env {
            name = "StringConnectionMongo"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "StringConnectionMongo"
              }
            }
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  metadata {
    name = "${var.app_name}-hpa"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 30
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "${var.app_name}-service"
  }

  spec {
    type = "LoadBalancer"
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = var.container_port
    }
  }
}
