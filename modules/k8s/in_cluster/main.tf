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

resource "kubernetes_secret" "argocd-dex" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata.0.name
    name      = "argocd-dex-secret"
  }
  data = {
    "dex.github.clientSecret" = var.argocd_github_app_secret
  }
}

resource "kubectl_manifest" "argocd" {
    for_each  = fileset("${path.module}/argocd/build/*.yaml")
    yaml_body = file(each.value)
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
