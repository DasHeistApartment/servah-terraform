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
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}

resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
  }
}

resource "kubernetes_ingress_v1" "master" {
  metadata {
    namespace = kubernetes_namespace.networking.metadata.0.name
    name      = "ingress-master"
    annotations = {
      "cert-manager.io/cluster-issuer"     = "letsencrypt"
      "nginx.org/mergeable-ingress-type"   = "master"
      "ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["home.crazypokemondev.de"]
      secret_name = "letsencrypt-staging"
    }

    rule {
      host = "home.crazypokemondev.de"
    }
  }
}
