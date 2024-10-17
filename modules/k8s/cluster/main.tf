terraform {
  required_providers {
    proxmox = {
      source  = "TheGameProfi/proxmox"
      version = "2.10.0"
    }
  }
}

resource "proxmox_vm_qemu" "k8s_controller" {
  name        = "k8s-controller"
  target_node = "servah"
  desc        = "The controller of the K8s cluster. Needs to be a VM because K8s requires several kernel details."
  onboot      = true
  vm_state    = "running"
  tablet      = false
  iso         = "local:iso/k8s-controller-template.iso" # stored in OneDrive, in case Proxmox server experiences data loss
  bios        = "seabios"
  qemu_os     = "other"

  cores  = 2
  memory = 2048

  disks {
    scsi {
      scsi0 {
        disk {
          storage    = "Kingston500GBNVMe1"
          size       = 8
          emulatessd = true
          replicate  = true
        }
      }
    }
  }

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = var.controller_mac
  }
}

resource "proxmox_vm_qemu" "k8s_node_0" {
  name        = "k8s-node-0"
  target_node = "servah"
  desc        = "The first node of the K8s cluster. Needs to be a VM because K8s requires several kernel details."
  onboot      = true
  vm_state    = "running"
  tablet      = false
  iso         = "local:iso/k8s-node-template.iso" # stored in OneDrive, in case Proxmox server experiences data loss
  bios        = "seabios"
  qemu_os     = "other"

  cores  = 4
  memory = 32768

  disks {
    scsi {
      scsi0 {
        disk {
          storage    = "Kingston500GBNVMe1"
          size       = 128
          emulatessd = true
          replicate  = true
        }
      }
      scsi1 {
        disk {
          storage    = "Kingston2TBNVMe1"
          size       = 128
          emulatessd = true
        }
      }
    }
  }

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = var.node_0_mac
  }

  provisioner "local-exec" {
    command = "until [ $(curl -k -f https://k8s-controller:6443/livez -o /dev/null -w '%%{http_code}\n' -s) -eq 200 ]; do sleep 2; done"
  }
}
