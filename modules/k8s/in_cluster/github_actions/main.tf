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

resource "helm_release" "actions_runner_controller" {
  name             = "actions-runner-controller"
  namespace        = "actions-runner-system"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  create_namespace = true

  set {
    name  = "authSecret.create"
    value = true
  }
  set {
    name  = "authSecret.github_token"
    value = var.github_pat_arc
  }
  set {
    name  = "githubWebhookServer.enabled"
    value = true
  }
}

# The webhook URL for this ingress would be https://home.crazypokemondev.de/actions-runner-controller-github-webhook-server
resource "kubernetes_ingress_v1" "github_webhook_server" {
  metadata {
    namespace = helm_release.actions_runner_controller.metadata.0.namespace
    name      = "actions-runner-controller-github-webhook-server"
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["home.crazypokemondev.de"]
      secret_name = "letsencrypt-staging"
    }

    rule {
      http {
        path {
          path = "/actions-runner-controller-github-webhook-server"
          path_type = "Prefix"
          backend {
            service {
              name = "actions-runner-controller-github-webhook-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
