terraform {
  required_providers = {
    kubernetes = {
      source  = "hashicorp/terraform"
      version = ">=2.0.0"
    }
  }
}

resource "kubernetes_namespace" "terraform" {
  name = "terraform"
}

