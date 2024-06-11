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

    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }
  data = {
    "dex.github.clientSecret" = var.argocd_github_app_secret
  }
}

resource "kubectl_manifest" "argocd" {
  for_each           = fileset("${path.module}/argocd/build", "*.yaml")
  yaml_body          = file("${path.module}/argocd/build/${each.value}")
  override_namespace = kubernetes_namespace.argocd.metadata.0.name
}

resource "kubernetes_ingress_v1" "argocd_master" {
  metadata {
    namespace = kubernetes_namespace.argocd.metadata.0.name
    name      = "argo-cd-master"
    annotations = {
      "cert-manager.io/cluster-issuer"     = "letsencrypt"
      "nginx.org/mergeable-ingress-type"   = "master"
      "ingress.kubernetes.io/ssl-redirect" = "false"
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

resource "kubectl_manifest" "gitops_project" {
  depends_on         = [kubectl_manifest.argocd]
  yaml_body          = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: gitops
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    name: 'in-cluster'
  sourceRepos:
  - '*'
EOF
  override_namespace = kubernetes_namespace.argocd.metadata.0.name
}

resource "kubectl_manifest" "gitops_root_app" {
  depends_on         = [kubectl_manifest.argocd, kubectl_manifest.gitops_project]
  yaml_body          = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-root
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: ${kubernetes_namespace.argocd.metadata.0.name}
    name: in-cluster
  source:
    directory:
      recurse: true
    path: root
    repoURL: 'https://github.com/DasHeistApartment/servah-gitops'
    targetRevision: HEAD
  sources: []
  project: ${kubectl_manifest.gitops_project.name}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  EOF
  override_namespace = kubernetes_namespace.argocd.metadata.0.name
  ignore_fields      = ["status"]
}
