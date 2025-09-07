locals {
  argocd_root_project_content = file("${path.module}/argocd/root_project.yaml")
  argocd_root_app_content     = file("${path.module}/argocd/root_app.yaml")
  argocd_dex_secret = templatefile("${path.module}/argocd/dex-secret.yaml",
    {
      argocd_github_app_secret = var.argocd_github_app_secret
    }
  )

  argocd_config_maps = file("${path.module}/argocd/config-maps.yaml")
}
