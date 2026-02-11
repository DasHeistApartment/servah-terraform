variable "proxmox_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "ssh_private_key" {
  type      = string
  sensitive = false // set to false to enable log from kubespray provisioner
}

variable "argocd_github_app_secret" {
  type      = string
  sensitive = true
}

variable "arc_github_token" {
  type      = string
  sensitive = true
}

variable "tfc_agent_token" {
  type      = string
  sensitive = true
}

variable "wwvote_bot_token" {
  type      = string
  sensitive = true
}

variable "wwvote_connection_string" {
  type      = string
  sensitive = true
}

resource "random_password" "wwvote_webhook_token" {
  length  = 16
  special = false
}

resource "random_password" "dex_headlamp_client_secret" {
  length  = 40
  special = false
}

variable "dex_db_password" {
  type      = string
  sensitive = true
}

locals {
  arc_pat_secret_content = templatefile("${path.module}/secrets/arc-pat.yaml",
    {
      github_token = var.arc_github_token
    }
  )
  tfc_agent_secret_content = templatefile("${path.module}/secrets/tfc-agent.yaml",
    {
      token = var.tfc_agent_token
    }
  )
  wwdeatch_secret_content = templatefile("${path.module}/secrets/wwdeatch.yaml",
    {
      bot_token         = var.wwvote_bot_token,
      webhook_token     = random_password.wwvote_webhook_token.result,
      connection_string = var.wwvote_connection_string
    }
  )
  dex_secret_content = templatefile("${path.module}/secrets/dex.yaml",
    {
      dex_headlamp_client_secret = random_password.dex_headlamp_client_secret.result,
      db_password                = var.dex_db_password
    }
  )
}
