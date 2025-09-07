terraform {
  cloud {
    organization = "das-heist-apartment"

    workspaces {
      name = "servah-host-kubernetes"
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
