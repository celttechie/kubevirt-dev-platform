terraform {
  required_version = ">= 1.6.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

# 1. Base OS Cloud Image Volume in Target Storage Pool
resource "libvirt_volume" "base_image" {
  name   = "${var.vm_name}-base.qcow2"
  pool   = var.storage_pool_name
  source = var.base_image_source
  format = "qcow2"
}

# 2. Copy-on-Write Root Disk Volume (120 GB) for Virtualization & OCI Artifacts
resource "libvirt_volume" "vm_disk" {
  name           = "${var.vm_name}-disk.qcow2"
  pool           = var.storage_pool_name
  base_volume_id = libvirt_volume.base_image.id
  format         = "qcow2"
  size           = var.disk_size_bytes
}

# 3. Cloud-Init Seed ISO with Deterministic Host and Client Keys
resource "libvirt_cloudinit_disk" "cloudinit" {
  name = "${var.vm_name}-cloudinit.iso"
  pool = var.storage_pool_name
  user_data = templatefile("${path.module}/templates/cloud_init.cfg", {
    hostname                 = var.vm_name
    admin_username           = var.admin_username
    ssh_public_key           = trimspace(file("${path.module}/${var.client_public_key_path}"))
    host_ed25519_private_key = trimspace(file("${path.module}/${var.host_private_key_path}"))
    host_ed25519_public_key  = trimspace(file("${path.module}/${var.host_public_key_path}"))
  })
  network_config = templatefile("${path.module}/templates/network_config.cfg", {
    mac_address = var.vm_mac
    ip_address  = var.vm_ip
    gateway     = var.network_gateway
    nameserver  = var.network_gateway
  })
}

# 4. Nested Hypervisor Domain with CPU host-passthrough
resource "libvirt_domain" "kubevirt_sandbox" {
  name   = var.vm_name
  memory = var.vm_memory_mb
  vcpu   = var.vm_vcpu
  # Guest agent is enabled in the guest OS for virsh snapshots, but disabled here
  # to prevent provider timeout while querying interfaces during early boot
  qemu_agent = false

  # Pass host CPU virtualization flags into guest VM (/dev/kvm VT-x)
  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name   = var.network_name
    mac            = var.vm_mac
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.vm_disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
