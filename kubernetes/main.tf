terraform {
  cloud {
    organization = "das-heist-apartment"

    workspaces {
      name = "servah-host-general"
    }
  }

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

#provider "kubernetes" {
# Will run in-cluster using a service account if the agent is already set up and will therefore need no credentials.
# If the agent is not yet running, make sure a temporary agent has access to the cluster by defining the KUBE_CONFIG_PATH variable.
# A command to do this on windows can be found below (make sure docker is installed and running).
# docker run --name tfc_agent_temp --env TFC_AGENT_TOKEN=%TOKEN% --env "KUBE_CONFIG_PATH=/home/tfc-agent/.kube/config" --mount type=bind,source="%userprofile%\.kube",target=/home/tfc-agent/.kube,readonly olfi01/custom-tfc-agent:latest
#}

#provider "helm" {
# Will use the same kubernetes config as the kubernetes provider
#}

#provider "kubectl" {
#  load_config_file = false # set by environment variable on runner
#}

module "networking" {
  source = "./networking"

  portforward_config_url = local.portforward_config_url
  acme_email             = local.acme_email
  metallb_address_pool   = local.metallb_address_pool
}

# note: check out https://github.com/JamesLaverack/holepunch for automatic port forwardings

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
      hosts       = [local.argocd_host]
      secret_name = "letsencrypt"
    }

    rule {
      host = local.argocd_host
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
      host = local.argocd_host

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
