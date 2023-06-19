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
