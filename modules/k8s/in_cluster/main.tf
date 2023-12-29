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
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.0"
    }
  }
}

module "networking" {
  source = "./networking"

  portforward_config_url = var.portforward_config_url
  acme_email             = var.acme_email
  metallb_address_pool   = var.metallb_address_pool
}

# note: check out https://github.com/JamesLaverack/holepunch for automatic port forwardings

module "kubernetes_terraform" {
  source = "./terraform"

  tfc_agent_token = var.tfc_agent_token
}

module "github_actions" {
  source = "./github_actions"

  github_pat_arc = var.github_pat_arc
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

module "argocd_kustomize" {
  source  = "kbst.xyz/catalog/custom-manifests/kustomization"
  version = "0.4.0"

  configuration = {
    apps = {
      namespace = kubernetes_namespace.argocd.metadata.0.name

      resources = [
        "${path.module}/argocd"
      ]
    }

    ops = {}

    config_map_generator = [{
      name      = "environment-variables-tf"
      namespace = kubernetes_namespace.argocd.metadata.0.name
      literals = [
        "ARGOCD_URL=https://${var.argocd_host}"
      ]
    }]

    secret_generator = [{
      name      = "argocd-dex-secret"
      namespace = kubernetes_namespace.argocd.metadata.0.name
      literals = [
        "dex.github.clientSecret=${var.argocd_github_app_secret}"
      ]
      options = {
        labels = {
          "app.kubernetes.io/part-of" = "argocd"
        }
      }
    }]

    common_labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
}

resource "kubernetes_ingress_v1" "argocd_master" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata.0.name
    name      = "argo-cd-master"
    annotations = {
      "cert-manager.io/cluster-issuer"   = "letsencrypt"
      "nginx.org/mergeable-ingress-type" = "master"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.argocd_host]
      secret_name = "letsencrypt"
    }

    rule {
      host = var.argocd_host
    }
  }
}

resource "kubernetes_ingress_v1" "argocd_minion" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata.0.name
    name      = "argo-cd-minion"
    annotations = {
      "nginx.org/mergeable-ingress-type" = "minion"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = var.argocd_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}
