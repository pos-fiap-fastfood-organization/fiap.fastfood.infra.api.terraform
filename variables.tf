variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type = string
}

variable "app_name" {
  type    = string
  default = "fiap-fastfood-api"
}

variable "docker_image" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "environment" {
  type    = string
  default = "Development"
}

variable "mercadopago_api_token" {
  type      = string
  sensitive = true
}

variable "mongo_password" {
  description = "Senha do usuário do MongoDB Atlas"
  type        = string
  sensitive   = true
}