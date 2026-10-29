resource "proxmox_virtual_environment_vm" "node" {
  for_each  = var.nodes
  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  tags      = ["homelab", "k8s", each.value.role]

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = "debian"
      keys     = [trimspace(var.ssh_public_key)]
    }
  }
}

# Inventaire ansible généré
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory/hosts.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/inventory.tftpl", {
    control_planes = { for name, n in var.nodes : name => n.ip if n.role == "control-plane" }
    workers        = { for name, n in var.nodes : name => n.ip if n.role == "worker" }
  })

  depends_on = [proxmox_virtual_environment_vm.node]
}