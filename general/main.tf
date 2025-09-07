// Remember to manually run an agent if the cluster is not up:
// podman run --rm --name tfc_agent_temp --env TFC_AGENT_TOKEN=%TOKEN% --env "KUBE_CONFIG_PATH=/home/tfc-agent/.kube/config" --mount type=bind,source="%userprofile%\.kube",target=/home/tfc-agent/.kube,readonly olfi01/custom-tfc-agent:latest

terraform {
  cloud {
    organization = "das-heist-apartment"

    workspaces {
      name = "servah-host-general"
    }
  }

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://servah-host.fritz.box:8006/api2/json"
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
}

resource "proxmox_vm_qemu" "k8s-control-node" {
  count = local.control_node_count

  name        = "k8s-control-node-${count.index}"
  target_node = "servah"

  clone = "ubuntu-2404-cloudinit-template"

  agent            = 1
  onboot           = true
  os_type          = "cloud-init"
  scsihw           = "virtio-scsi-single"
  hotplug          = "network,disk,usb,memory,cpu"
  numa             = true
  automatic_reboot = true
  bootdisk         = "virtio0"

  cores  = 4
  memory = 4096

  desc = "This VM is a control node for the kubernetes cluster, managed by Terraform."

  disks {
    virtio {
      virtio0 {
        disk {
          size     = "8G"
          storage  = "Kingston500GBNVMe1"
          iothread = true
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "Kingston500GBNVMe1"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial {
    id = 0
  }

  ipconfig0 = "ip=${cidrhost("192.168.21.0/24", 10 + count.index)}/23,gw=192.168.20.1"

  ciuser  = "ubuntu"
  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI03+GnuRPXNFV8BlaTt0K3hBGmXU1DVkBs8DhQQBmfVmJuTkDk3Z0dTbSeNGjdfYzAUAjAqsDUi2D0IHC7Rq2toUWknbEzv8pClrexAOJzjpXL9qQvNe4QofipZ8TUSqztl4xRGAWArPZuZ1v1PL1sKBnu/VC0XdSG1FZfWpCaHL50Awpu2iK4BGL2+ADAUCRr6CLCy5CN6Yi757CFcB9H7GjCmmuqzC3LM9XlUYOB3YCQ1IfVaZ7Yku0a2s4I8dNvVAbcyD34wrDSS3TPTgLV/AvTNb7M0QCaMrGXBZcSjP2vl5fte/7AsBQlLuAUWckl1pIKzgBJJ3l85yVD3pZkZ/Es521vOXGCcvLaXmDXZfaNML6rjqMLsdq8srhvyviyr70IgXpkP5zcb3ROzFGWgLXfn6ungKbxb/tis4cyJFniN7nIAfUN4I9ShaB0TM9kcTmnVsFk2XRNi3VGALz6Zt8u1EoyPx3yQXwuSnu6wr4dVq1+Guzo5vMl7nqaPbUycb9HZDsgNgtmykGeFBP9AeD6/R0PJZo1a9D3U73gcF2T9CGjDR4011puwghxOcwLxfWKG/cU6jMAxvlGSM3iJPW3B2m7PXQE8DxK7eQSZa8Tpk1xcnmFAWklryG3DB1dyjGgDHUetRLnR1ftG0ieb+KjhNphOQTlNUKdxlY4w== k8s-admin@cluster.local
EOF

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "proxmox_vm_qemu" "k8s-worker-node" {
  count = local.worker_node_count

  name        = "k8s-worker-node-${count.index}"
  target_node = "servah"

  clone = "ubuntu-2404-cloudinit-template"

  agent            = 1
  onboot           = true
  os_type          = "cloud-init"
  scsihw           = "virtio-scsi-single"
  hotplug          = "network,disk,usb,memory,cpu"
  numa             = true
  automatic_reboot = true
  bootdisk         = "virtio0"

  cores  = 8
  memory = 32768

  desc = "This VM is a worker node for the kubernetes cluster, managed by Terraform."

  disks {
    virtio {
      virtio0 {
        disk {
          size     = "64G"
          storage  = "Kingston2TBNVMe1"
          iothread = true
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "Kingston2TBNVMe1"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial {
    id = 0
  }

  ipconfig0 = "ip=${cidrhost("192.168.21.0/24", 20 + count.index)}/23,gw=192.168.20.1"

  ciuser  = "ubuntu"
  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI03+GnuRPXNFV8BlaTt0K3hBGmXU1DVkBs8DhQQBmfVmJuTkDk3Z0dTbSeNGjdfYzAUAjAqsDUi2D0IHC7Rq2toUWknbEzv8pClrexAOJzjpXL9qQvNe4QofipZ8TUSqztl4xRGAWArPZuZ1v1PL1sKBnu/VC0XdSG1FZfWpCaHL50Awpu2iK4BGL2+ADAUCRr6CLCy5CN6Yi757CFcB9H7GjCmmuqzC3LM9XlUYOB3YCQ1IfVaZ7Yku0a2s4I8dNvVAbcyD34wrDSS3TPTgLV/AvTNb7M0QCaMrGXBZcSjP2vl5fte/7AsBQlLuAUWckl1pIKzgBJJ3l85yVD3pZkZ/Es521vOXGCcvLaXmDXZfaNML6rjqMLsdq8srhvyviyr70IgXpkP5zcb3ROzFGWgLXfn6ungKbxb/tis4cyJFniN7nIAfUN4I9ShaB0TM9kcTmnVsFk2XRNi3VGALz6Zt8u1EoyPx3yQXwuSnu6wr4dVq1+Guzo5vMl7nqaPbUycb9HZDsgNgtmykGeFBP9AeD6/R0PJZo1a9D3U73gcF2T9CGjDR4011puwghxOcwLxfWKG/cU6jMAxvlGSM3iJPW3B2m7PXQE8DxK7eQSZa8Tpk1xcnmFAWklryG3DB1dyjGgDHUetRLnR1ftG0ieb+KjhNphOQTlNUKdxlY4w== k8s-admin@cluster.local
EOF

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "proxmox_vm_qemu" "kubespray-host" {
  name        = "kubespray-host"
  target_node = "servah"

  clone = "ubuntu-2404-cloudinit-template"

  agent            = 1
  onboot           = true
  os_type          = "cloud-init"
  scsihw           = "virtio-scsi-single"
  hotplug          = "network,disk,usb,memory,cpu"
  numa             = true
  automatic_reboot = true
  bootdisk         = "virtio0"

  cores  = 2
  memory = 2048

  desc = "This the kubespray host, managed by Terraform."

  disks {
    virtio {
      virtio0 {
        disk {
          size     = "10G"
          storage  = "Kingston500GBNVMe1"
          iothread = true
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "Kingston500GBNVMe1"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial {
    id = 0
  }

  ipconfig0 = "ip=${cidrhost("192.168.21.0/24", 5)}/23,gw=192.168.20.1"

  ciuser  = "ubuntu"
  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDI03+GnuRPXNFV8BlaTt0K3hBGmXU1DVkBs8DhQQBmfVmJuTkDk3Z0dTbSeNGjdfYzAUAjAqsDUi2D0IHC7Rq2toUWknbEzv8pClrexAOJzjpXL9qQvNe4QofipZ8TUSqztl4xRGAWArPZuZ1v1PL1sKBnu/VC0XdSG1FZfWpCaHL50Awpu2iK4BGL2+ADAUCRr6CLCy5CN6Yi757CFcB9H7GjCmmuqzC3LM9XlUYOB3YCQ1IfVaZ7Yku0a2s4I8dNvVAbcyD34wrDSS3TPTgLV/AvTNb7M0QCaMrGXBZcSjP2vl5fte/7AsBQlLuAUWckl1pIKzgBJJ3l85yVD3pZkZ/Es521vOXGCcvLaXmDXZfaNML6rjqMLsdq8srhvyviyr70IgXpkP5zcb3ROzFGWgLXfn6ungKbxb/tis4cyJFniN7nIAfUN4I9ShaB0TM9kcTmnVsFk2XRNi3VGALz6Zt8u1EoyPx3yQXwuSnu6wr4dVq1+Guzo5vMl7nqaPbUycb9HZDsgNgtmykGeFBP9AeD6/R0PJZo1a9D3U73gcF2T9CGjDR4011puwghxOcwLxfWKG/cU6jMAxvlGSM3iJPW3B2m7PXQE8DxK7eQSZa8Tpk1xcnmFAWklryG3DB1dyjGgDHUetRLnR1ftG0ieb+KjhNphOQTlNUKdxlY4w== k8s-admin@cluster.local
EOF

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "null_resource" "setup_kubespray" {
  provisioner "remote-exec" {
    inline = [
      local.setup_kubespray_script_content,
      "echo \"${var.ssh_private_key}\" | base64 -d > ${local.kubespray_data_dir}/id_rsa",
      <<-EOT
      cat <<EOF > ${local.kubespray_data_dir}/inventory.ini
      ${local.kubespray_inventory_content}
      EOF
      EOT
      ,
      <<-EOT
      cat <<EOF > ${local.kubespray_data_dir}/k8s-cluster.yml
      ${local.kubespray_k8s_config_content}
      EOF
      EOT
      ,
      <<-EOT
      cat <<EOF > ${local.kubespray_data_dir}/addons.yml
      ${local.kubespray_addon_config_content}
      EOF
      EOT
      ,
      "chmod 600 ${local.kubespray_data_dir}/*",
      local.install_kubernetes_script_content
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = base64decode(var.ssh_private_key)
    host        = proxmox_vm_qemu.kubespray-host.ssh_host
    port        = 22
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    proxmox_vm_qemu.kubespray-host,
    proxmox_vm_qemu.k8s-control-node,
    proxmox_vm_qemu.k8s-worker-node
  ]
}

resource "null_resource" "setup_argocd_root_app" {
  provisioner "remote-exec" {
    inline = [
      "mkdir argocd_data",
      <<-EOT
      cat <<'EOF' > argocd_data/project.yaml
      ${local.argocd_root_project_content}
      EOF
      EOT
      ,
      <<-EOT
      cat <<'EOF' > argocd_data/app.yaml
      ${local.argocd_root_app_content}
      EOF
      EOT
      ,
      <<-EOT
      cat <<'EOF' > argocd_data/config-maps.yaml
      ${local.argocd_config_maps}
      EOF
      EOT
      ,
      <<-EOT
      cat <<EOF > argocd_data/dex-secret.yaml
      ${local.argocd_dex_secret}
      EOF
      EOT
      ,
      "sudo kubectl apply -n argocd -f argocd_data/project.yaml -f argocd_data/app.yaml -f argocd_data/dex-secret.yaml --server-side"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = base64decode(var.ssh_private_key)
    host        = proxmox_vm_qemu.k8s-control-node[0].ssh_host
    port        = 22
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    null_resource.setup_kubespray,
    proxmox_vm_qemu.kubespray-host,
    proxmox_vm_qemu.k8s-control-node,
    proxmox_vm_qemu.k8s-worker-node
  ]
}
