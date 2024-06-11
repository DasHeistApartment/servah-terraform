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

resource "helm_release" "nginx_controller" {
  namespace = "ingress-nginx"

  name             = "nginx-controller"
  repository       = "oci://ghcr.io/nginxinc/charts"
  chart            = "nginx-ingress"
  version          = "0.17.1"
  create_namespace = true

  set {
    name  = "controller.extraArgs.enable-ssl-passthrough"
    value = ""
  }
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

resource "kubectl_manifest" "acme_cluster_issuer" {
  depends_on = [helm_release.cert_manager]
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: ${var.acme_email}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-staging
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
          ingressTemplate:
            metadata:
              annotations:
                nginx.org/mergeable-ingress-type: minion

YAML
}

resource "kubectl_manifest" "acme_cluster_issuer_prod" {
  depends_on = [helm_release.cert_manager]
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: ${var.acme_email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
          ingressTemplate:
            metadata:
              annotations:
                nginx.org/mergeable-ingress-type: minion

YAML
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

resource "kubectl_manifest" "metallb_default_address_pool" {
  depends_on = [helm_release.metal_lb]

  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - ${join("\n- ", var.metallb_address_pool)}
  avoidBuggyIPs: true
YAML
}
