variable "portforward_config_url" {
  type = string
}

variable "acme_email" {
  type = string
}

variable "metallb_address_pool" {
  type = list(string)
}

variable "argocd_url" {
  type = string
}
