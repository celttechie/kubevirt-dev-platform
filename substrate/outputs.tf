output "vm_name" {
  description = "Name of the nested virtualization sandbox domain"
  value       = libvirt_domain.kubevirt_sandbox.name
}

output "vm_ip" {
  description = "Static IP address assigned to the nested sandbox domain"
  value       = var.vm_ip
}

output "vm_mac" {
  description = "Configured MAC address"
  value       = var.vm_mac
}

output "ssh_command" {
  description = "Strict-verified SSH connection command"
  value       = "ssh -F .ssh/config kubevirt-sandbox"
}

output "storage_pool" {
  description = "Libvirt storage pool backing the VM disk"
  value       = var.storage_pool_name
}
