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

resource "kubernetes_namespace" "metal_lb" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "metal_lb" {
  name       = "metallb"
  namespace  = kubernetes_namespace.metal_lb.metadata.0.name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
}

resource "helm_release" "metal_lb_setup" {
  namespace = helm_release.metal_lb.metadata.0.namespace

  name  = "metallb-setup"
  chart = "./charts/metallb-setup"
}

resource "helm_release" "nginx_controller" {
  name       = "nginx-controller"
  repository = "oci://ghcr.io/nginxinc/charts"
  chart      = "nginx-ingress"
  version    = "0.17.1"

  depends_on = [helm_release.metal_lb_setup]
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
  chart = "./charts/acme-setup"
}

output "tls_secret_name" {
  value = yamldecode(helm_release.acme_setup.metadata.0.values).secret.staging
}
