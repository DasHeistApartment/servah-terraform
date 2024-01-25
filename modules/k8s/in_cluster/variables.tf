variable "portforward_config_url" {
  type = string
}

variable "acme_email" {
  type = string
}

variable "metallb_address_pool" {
  type = list(string)
}

variable "argocd_host" {
  type = string
}

variable "argocd_host_grpc" {
  type = string
}

variable "argocd_github_app_id" {
  type = string
}
