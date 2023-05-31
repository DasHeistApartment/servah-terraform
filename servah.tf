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
  }
}

provider "proxmox" {
  pm_api_url          = "https://servah-host:8006/api2/json"
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
}

provider "kubernetes" {

}

module "proxmox_kubernetes_cluster" {
  source = "./modules/k8s/cluster"
}

module "kubernetes_terraform" {
  source = "./modules/k8s/terraform"

  tfc_agent_token = var.tfc_agent_token
}
