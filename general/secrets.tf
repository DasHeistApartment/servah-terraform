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
