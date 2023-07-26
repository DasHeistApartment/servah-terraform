terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

resource "helm_release" "nginx_controller" {
  namespace = "ingress-nginx"

  name             = "nginx-controller"
  repository       = "oci://ghcr.io/nginxinc/charts"
  chart            = "nginx-ingress"
  version          = "0.17.1"
  create_namespace = true
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "acme_setup" {
  namespace = helm_release.cert_manager.metadata.0.namespace

  name  = "acme-setup"
  chart = "${path.module}/charts/acme-setup"

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
  }
}

resource "kubernetes_deployment" "portforward" {
  metadata {
    namespace = kubernetes_namespace.networking.metadata.0.name
    name      = "portforward"

    labels = {
      deployment = "portforward"
      app        = "portforward"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        deployment = "portforward"
      }
    }

    template {
      metadata {
        namespace = kubernetes_namespace.networking.metadata.0.name
        labels = {
          deployment = "portforward"
          app        = "portforward"
        }
      }

      spec {
        container {
          name  = "python"
          image = "olfi01/servah-portforward:latest"

          env {
            name  = "CONFIG_URL"
            value = var.portforward_config_url
          }
          port {
            container_port = 80
            name           = "http"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "portforward" {
  metadata {
    name      = "portforward-service"
    namespace = kubernetes_namespace.networking.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.portforward.metadata.0.labels.app
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = kubernetes_deployment.portforward.spec.0.template.0.spec.0.container.0.port.0.name
      name        = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "portforward" {
  metadata {
    namespace = kubernetes_namespace.networking.metadata.0.name
    name      = "ingress-portforward"
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["home.crazypokemondev.de"]
      secret_name = "letsencrypt-staging"
    }

    rule {
      http {
        path {
          path      = "/portforward"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.portforward.metadata.0.name
              port {
                name = kubernetes_service.portforward.spec.0.port.0.name
              }
            }
          }
        }
      }
    }
  }
}
