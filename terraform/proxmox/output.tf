output "node_ips" {
  description = "IP de chaque noeud"
  value       = { for name, n in var.nodes : name => n.ip }
}