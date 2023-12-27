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

data "http" "argocd_manifest_raw" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.3/manifests/install.yaml"
}

data "kubectl_file_documents" "argocd_manifest_doc" {
  content = data.http.argocd_manifest_raw.response_body
}

resource "kubectl_manifest" "argocd" {
  for_each  = data.kubectl_file_documents.argocd_manifest_doc.manifests
  yaml_body = each.value
  wait      = true
  override_namespace = kubernetes_namespace.argocd.metadata.0.name
}

resource "kubernetes_ingress_v1" "argocd_master" {
  metadata {
    namespace   = kubernetes_namespace.argocd.metadata.0.name
    name        = "argo-cd-master"
    annotations = {
      "cert-manager.io/cluster-issuer"               = "letsencrypt"
      "nginx.org/mergeable-ingress-type"             = "master"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = ["argo-cd.crazypokemondev.de"]
      secret_name = "letsencrypt"
    }

    rule {
      host = "argo-cd.crazypokemondev.de"
    }
  }
}

resource "kubernetes_ingress_v1" "argocd_minion" {
  metadata {
    namespace   = kubernetes_namespace.argocd.metadata.0.name
    name        = "argo-cd-minion"
    annotations = {
      "nginx.org/mergeable-ingress-type"   = "minion"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "argo-cd.crazypokemondev.de"

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
