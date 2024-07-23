locals {
  portforward_config_url = "https://raw.githubusercontent.com/DasHeistApartment/service-configurations/main/networking/portforward.json"
  acme_email             = "flommeyer@gmail.com"

  metallb_address_pool = [
    "192.168.20.62/32"
  ]
  argocd_host          = "argo-cd.crazypokemondev.de"
  argocd_github_app_id = "fd43b1e770612fb89f08"
  node_0_mac = "96:ca:03:e1:dc:12"
  controller_mac = "c6:2e:50:01:72:04"
}
