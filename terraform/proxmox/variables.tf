variable "proxmox_endpoint" {
  type    = string
  default = "https://192.168.100.10:8006/"
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true # lu depuis TF_VAR_proxmox_api_token, masqué dans les sorties
}

variable "ssh_public_key" {
  type = string
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "gateway" {
  type    = string
  default = "192.168.100.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.100.1"]
}

variable "nodes" {
  description = "Nœuds du cluster, indexés par leur nom"
  type = map(object({
    vm_id  = number
    ip     = string
    cores  = number
    memory = number # en Mo
    disk   = number # en Go
    role   = string
  }))

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["control-plane", "worker"], n.role)])
    error_message = "Chaque noeud doit avoir le rôle control-plane ou worker."
  }
}