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
      "nginx.org/mergeable-ingress-type"             = "minion"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "home.crazypokemondev.de"

      http {
        path {
          path      = "/actions-runner-controller-github-webhook-server"
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

resource "kubectl_manifest" "organization_runner_deployment" {
  depends_on = [helm_release.actions_runner_controller]
  yaml_body  = <<YAML
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: organization-runner
spec:
  template:
    spec:
      organization: DasHeistApartment
      labels:
        - intranet
YAML
}

resource "kubectl_manifest" "organization_runner_autoscaler" {
  depends_on = [helm_release.actions_runner_controller]
  yaml_body  = <<YAML
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: organization-runners
spec:
  minReplicas: 0
  maxReplicas: 5
  scaleTargetRef:
    kind: RunnerDeployment
    name: organization-runner
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
      duration: "35m"
YAML
}

resource "kubectl_manifest" "chormaeleon_runner_deployment" {
  depends_on = [helm_release.actions_runner_controller]
  yaml_body  = <<YAML
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: chormaeleon-runner
spec:
  template:
    spec:
      organization: Chormaeleon
YAML
}

resource "kubectl_manifest" "chormaeleon_runner_autoscaler" {
  depends_on = [helm_release.actions_runner_controller]
  yaml_body  = <<YAML
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: chormaeleon-runners
spec:
  minReplicas: 0
  maxReplicas: 3
  scaleTargetRef:
    kind: RunnerDeployment
    name: chormaeleon-runner
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
      duration: "35m"
YAML
}
