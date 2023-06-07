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

#provider "kubernetes" {
# Will run in-cluster using a service account if the agent is already set up and will therefore need no credentials.
# If the agent is not yet running, make sure a temporary agent has access to the cluster by defining the KUBE_CONFIG_PATH variable.
# A command to do this on windows can be found below (make sure docker is installed and running).
# docker run --name tfc_agent_temp --env TFC_AGENT_TOKEN=%TOKEN% --env "KUBE_CONFIG_PATH=/home/tfc-agent/.kube/config" --mount type=bind,source="%userprofile%\.kube",target=/home/tfc-agent/.kube,readonly hashicorp/tfc-agent:latest
#}

#provider "helm" {
# Will use the same kubernetes config as the kubernetes provider
#}

#module "networking" {
#source = "./networking"
#}

# note: check out https://github.com/JamesLaverack/holepunch for automatic port forwardings

module "kubernetes_terraform" {
  source = "./terraform"

  tfc_agent_token = var.tfc_agent_token
}
