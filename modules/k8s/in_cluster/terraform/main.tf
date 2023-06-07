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
  depends_on = [kubernetes_namespace.terraform]
  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent-token"
  }

  data = {
    "token" = var.tfc_agent_token
  }
}

resource "kubernetes_service_account" "tfc_agent" {
  depends_on = [kubernetes_namespace.terraform]

  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent"
  }
}

resource "kubernetes_cluster_role_binding" "tfc_agent" {
  depends_on = [kubernetes_service_account.tfc_agent]

  metadata {
    name = "tfc-agent-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tfc_agent.metadata.0.name
    namespace = kubernetes_namespace.terraform.metadata.0.name
  }
}

resource "kubernetes_deployment" "tfc_agent" {
  wait_for_rollout = false

  depends_on = [kubernetes_service_account.tfc_agent, kubernetes_secret.tfc_agent_token, kubernetes_namespace.terraform]

  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent"

    labels = {
      deployment = "tfc-agent"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        deployment = "tfc-agent"
      }
    }

    template {
      metadata {
        namespace = kubernetes_namespace.terraform.metadata.0.name
        labels = {
          deployment = "tfc-agent"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.tfc_agent.metadata.0.name

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
  }
}
