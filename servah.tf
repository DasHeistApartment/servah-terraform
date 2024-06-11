terraform {
  cloud {
    organization = "das-heist-apartment"

    workspaces {
      name = "servah-host-workspace"
    }
  }
}

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
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

provider "proxmox" {
  pm_api_url          = "https://servah-host:8006/api2/json"
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
}

#provider "kubernetes" {
# Will run in-cluster using a service account if the agent is already set up and will therefore need no credentials.
# If the agent is not yet running, make sure a temporary agent has access to the cluster by defining the KUBE_CONFIG_PATH variable.
# A command to do this on windows can be found below (make sure docker is installed and running).
# docker run --name tfc_agent_temp --env TFC_AGENT_TOKEN=%TOKEN% --env "KUBE_CONFIG_PATH=/home/tfc-agent/.kube/config" --mount type=bind,source="%userprofile%\.kube",target=/home/tfc-agent/.kube,readonly hashicorp/tfc-agent:latest
#}

#provider "helm" {
# Will use the same kubernetes config as the kubernetes provider
#}

provider "kubectl" {
  load_config_file = false
}

module "proxmox_kubernetes_cluster" {
  source = "./modules/k8s/cluster"
}

module "kubernetes_in_cluster" {
  source = "./modules/k8s/in_cluster"

  github_pat_arc           = var.github_pat_arc
  portforward_config_url   = local.portforward_config_url
  acme_email               = local.acme_email
  metallb_address_pool     = local.metallb_address_pool
  argocd_host              = local.argocd_host
  argocd_github_app_id     = local.argocd_github_app_id
  argocd_github_app_secret = var.argocd_github_app_secret

  depends_on = [module.proxmox_kubernetes_cluster]
}
