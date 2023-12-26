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
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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

data "kustomization_build" "argocd" {
  path = "./argocd"
}

resource "kustomization_resource" "argocd_p0" {
  for_each = data.kustomization_build.argocd.ids_prio[0]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_build.argocd.manifests[each.value])
    : data.kustomization_build.argocd.manifests[each.value]
  )
}

resource "kustomization_resource" "argocd_p1" {
  for_each = data.kustomization_build.argocd.ids_prio[1]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_build.argocd.manifests[each.value])
    : data.kustomization_build.argocd.manifests[each.value]
  )

  depends_on = [kustomization_resource.argocd_p0]
}

resource "kustomization_resource" "argocd_p2" {
  for_each = data.kustomization_build.argocd.ids_prio[2]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_build.argocd.manifests[each.value])
    : data.kustomization_build.argocd.manifests[each.value]
  )

  depends_on = [kustomization_resource.argocd_p1]
}
