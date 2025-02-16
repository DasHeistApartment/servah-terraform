resource "kubernetes_namespace" "actions_runner_system" {
  metadata {
    name = "actions-runner-system"
  }
}

resource "kubernetes_secret" "arc_pat_github" {
  metadata {
    namespace = kubernetes_namespace.actions_runner_system.metadata.0.name
    name      = "controller-manager"
  }
  data = {
    "github_token" = var.arc_github_token
  }
}

resource "kubernetes_namespace" "terraform" {
  metadata {
    name = "terraform"
  }
}

resource "kubernetes_secret" "terraform_agent_token" {
  metadata {
    namespace = kubernetes_namespace.terraform.metadata.0.name
    name      = "tfc-agent-token"
  }
  data = {
    "token" = var.tfc_agent_token
  }
}

resource "kubernetes_namespace" "wwdeatch" {
  metadata {
    name = "wwdeatch"
  }
}

resource "random_password" "wwvote_webhook_token" {
  length = 16
}

resource "kubernetes_secret" "wwdeatch_bot_secrets" {
  metadata {
    namespace = kubernetes_namespace.wwdeatch.metadata.0.name
    name      = "bot-secrets"
  }
  data = {
    "bot-token"         = var.wwvote_bot_token
    "webhook-token"     = random_password.wwvote_webhook_token.result
    "connection-string" = var.wwvote_connection_string
  }
}
