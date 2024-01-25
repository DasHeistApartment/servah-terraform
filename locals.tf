locals {
  portforward_config_url = "https://raw.githubusercontent.com/DasHeistApartment/service-configurations/main/networking/portforward.json"
  acme_email             = "flommeyer@gmail.com"

  metallb_address_pool = [
    "192.168.20.194/32"
  ]
  argocd_host          = "argo-cd.crazypokemondev.de"
  argocd_github_app_id = "fd43b1e770612fb89f08"
}
