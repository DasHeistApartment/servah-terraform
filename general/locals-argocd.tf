locals {
  argocd_root_project_content = file("${path.module}/argocd/root_project.yaml")
  argocd_root_app_content     = file("${path.module}/argocd/root_app.yaml")
}
