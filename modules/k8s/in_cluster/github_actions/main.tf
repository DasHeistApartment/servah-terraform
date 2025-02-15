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
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
  }
}

removed {
  from = helm_release.actions_runner_controller

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_ingress_v1.github_webhook_server

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.organization_runner_deployment

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.organization_runner_autoscaler

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.chormaeleon_runner_deployment

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.chormaeleon_runner_autoscaler

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.crazypokemondev_runner_deployment

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.crazypokemondev_runner_autoscaler

  lifecycle {
    destroy = false
  }
}
