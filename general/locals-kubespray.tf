locals {
  kubespray_data_dir = "$HOME/kubespray_data"

  setup_kubespray_script_content = templatefile(
    "${path.module}/scripts/setup_kubespray.sh",
    {
      kubespray_data_dir = local.kubespray_data_dir
    }
  )

  install_kubernetes_script_content = templatefile(
    "${path.module}/scripts/install_kubernetes.sh",
    {
      kubespray_data_dir = local.kubespray_data_dir,
      kubespray_image    = "quay.io/kubespray/kubespray:v2.28.0"
    }
  )

  kubespray_inventory_content = templatefile(
    "${path.module}/kubespray/inventory.ini",
    {
      cp_nodes     = join("\n", [for host in proxmox_vm_qemu.k8s-control-node : join("", [host.name, " ansible_ssh_host=${host.ssh_host}", " ansible_connection=ssh"])])
      worker_nodes = join("\n", [for host in proxmox_vm_qemu.k8s-worker-node : join("", [host.name, " ansible_ssh_host=${host.ssh_host}", " ansible_connection=ssh"])])
    }
  )

  kubespray_k8s_config_content = templatefile(
    "${path.module}/kubespray/k8s-cluster.yaml",
    {
      kube_network_plugin        = local.kube_network_plugin
      cluster_name               = "cluster.local"
      enable_nodelocaldns        = true
      persistent_volumes_enabled = false
    }
  )

  kubespray_addon_config_content = templatefile(
    "${path.module}/kubespray/addons.yaml",
    {
      helm_enabled          = false
      ingress_nginx_enabled = true
      argocd_enabled        = true
      argocd_version        = "3.1.4"
      metallb_ip_range      = "192.168.21.50-192.168.21.50"
    }
  )

}
