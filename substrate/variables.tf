variable "libvirt_uri" {
  type        = string
  description = "Libvirt daemon connection URI"
  default     = "qemu+ssh://admin@kvm-host/system"
}

variable "vm_name" {
  type        = string
  description = "Name of the nested virtualization sandbox domain"
  default     = "kubevirt-sandbox-vm"
}

variable "vm_memory_mb" {
  type        = number
  description = "Memory allocated to nested virtualization domain in MB"
  default     = 32768 # 32 GB
}

variable "vm_vcpu" {
  type        = number
  description = "vCPUs allocated to nested virtualization domain"
  default     = 8
}

variable "storage_pool_name" {
  type        = string
  description = "Target libvirt storage pool for base image and VM disk"
  default     = "ocp_nvme" # NVMe pool on /mnt/nvme_data/ocp_storage
}

variable "base_image_source" {
  type        = string
  description = "Base cloud image URL or local path on host"
  default     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "disk_size_bytes" {
  type        = number
  description = "Root disk volume size in bytes"
  default     = 128849018880 # 120 GB
}

variable "network_name" {
  type        = string
  description = "Libvirt network to attach the VM interface"
  default     = "default"
}

variable "vm_mac" {
  type        = string
  description = "Deterministic MAC address for static IP binding"
  default     = "52:54:00:22:6b:50"
}

variable "vm_ip" {
  type        = string
  description = "Static IP address for the nested sandbox VM"
  default     = "192.168.122.50"
}

variable "network_gateway" {
  type        = string
  description = "Default gateway on the network"
  default     = "192.168.122.1"
}

variable "admin_username" {
  type        = string
  description = "Administrative user created by cloud-init"
  default     = "admin"
}

variable "client_public_key_path" {
  type        = string
  description = "Path to client SSH public key authorized for admin user"
  default     = "keys/id_kubevirt_dev_ed25519.pub"
}

variable "host_private_key_path" {
  type        = string
  description = "Path to deterministic host ED25519 private key"
  default     = "keys/ssh_host_ed25519_key"
}

variable "host_public_key_path" {
  type        = string
  description = "Path to deterministic host ED25519 public key"
  default     = "keys/ssh_host_ed25519_key.pub"
}
