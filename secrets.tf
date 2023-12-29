variable "proxmox_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_token_secret" {
  type      = string
  sensitive = true
}

variable "tfc_agent_token" {
  type      = string
  sensitive = true
}

variable "github_pat_arc" {
  type      = string
  sensitive = true
}

variable "argocd_github_app_secret" {
  type      = string
  sensitive = true
}
