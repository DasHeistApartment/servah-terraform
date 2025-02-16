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
