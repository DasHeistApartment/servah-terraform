terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

resource "kubernetes_namespace" "terraform" {
  metadata {
    name = "terraform"
  }
}

resource "kubernetes_secret" "tfc_agent_token" {
  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent-token"
  }

  data = {
    "token" = var.tfc_agent_token
  }
}

resource "kubernetes_pod" "tfc_agent" {
  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent"
  }
  spec {
    container {
      name  = "agent"
      image = "hashicorp/tfc-agent:latest"
      env {
        name = "TFC_AGENT_TOKEN"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.tfc_agent_token.metadata.0.name
            key  = keys(kubernetes_secret.tfc_agent_token.data).0
          }
        }
      }
    }
  }
}
