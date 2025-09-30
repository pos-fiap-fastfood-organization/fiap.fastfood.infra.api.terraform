provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# ConfigMap
resource "kubernetes_config_map" "app" {
  metadata {
    name = "${var.app_name}-config"
  }

  data = {
    MERCADOPAGO_API_URL      = "https://api.mercadopago.com"
    ASPNETCORE_ENVIRONMENT  = var.environment
  }
}

# Secret
resource "kubernetes_secret" "app" {
  metadata {
    name = "${var.app_name}-secret"
  }

  type = "Opaque"

  data = {
    MERCADOPAGO_API_TOKEN = var.mercadopago_token
    StringConnectionMongo = var.mongo_connection
  }
}

# Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name   = var.app_name
    labels = { app = var.app_name }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.app_name }
    }

    template {
      metadata {
        labels = { app = var.app_name }
      }

      spec {
        container {
          name  = var.app_name
          image = var.docker_image
          ports { container_port = var.container_port }

          env {
            name = "MERCADOPAGO_API_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app.metadata[0].name
                key  = "MERCADOPAGO_API_TOKEN"
              }
            }
          }

          env {
            name = "StringConnectionMongo"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app.metadata[0].name
                key  = "StringConnectionMongo"
              }
            }
          }

          env_from {
            config_map_ref { name = kubernetes_config_map.app.metadata[0].name }
          }

          resources {
            limits   = { cpu = "100m", memory = "128Mi" }
            requests = { cpu = "50m", memory = "64Mi" }
          }
        }
      }
    }
  }
}

# Service
resource "kubernetes_service" "app" {
  metadata {
    name = "${var.app_name}-service"
  }

  spec {
    selector = { app = var.app_name }

    port {
      port        = 80
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
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
          type               = "Utilization"
          average_utilization = 30
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 60
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 15
        }
      }
      scale_up {
        stabilization_window_seconds = 0
        policy {
          type           = "Percent"
          value          = 10
          period_seconds = 15
        }
        policy {
          type           = "Pods"
          value          = 1
          period_seconds = 15
        }
        select_policy = "Max"
      }
    }
  }
}