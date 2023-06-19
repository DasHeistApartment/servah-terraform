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
  }
}

provider "proxmox" {
  pm_api_url          = "https://servah-host:8006/api2/json"
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
}

module "proxmox_kubernetes_cluster" {
  source = "./modules/k8s/cluster"
}

module "kubernetes_in_cluster" {
  source = "./modules/k8s/in_cluster"

  github_pat_arc = var.github_pat_arc

  depends_on = [module.proxmox_kubernetes_cluster]
}
