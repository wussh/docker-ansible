provider "google" {
  project = "wushonline"
  region  = "asia-southeast2"
  zone    = "asia-southeast2-a"
}

resource "tls_private_key" "master_key" {
  algorithm = "RSA"
}

resource "google_compute_network" "custom_vpc" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  network       = google_compute_network.custom_vpc.name
  ip_cidr_range = "10.0.0.0/24"
  region        = "asia-southeast2"
}

resource "google_compute_instance" "master" {
  name         = "master-vm"
  machine_type = "e2-small"
  zone         = "asia-southeast2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20250110"
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.master_key.public_key_openssh}"
  }

  network_interface {
    network = google_compute_network.custom_vpc.name
    subnetwork = google_compute_subnetwork.custom_subnet.name
    access_config {}
  }

  tags = ["all-ports"]
}

resource "google_compute_firewall" "allow_all_ports" {
  name    = "allow-all-ports"
  network = google_compute_network.custom_vpc.name

  allow {
    protocol = "tcp"
    ports     = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports     = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["all-ports", "vpn"]
}

output "master_vm_name" {
  value       = google_compute_instance.master.name
  description = "The name of the master VM instance"
}

output "master_vm_public_ip" {
  value       = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the master VM instance"
}

output "master_private_key" {
  value       = tls_private_key.master_key.private_key_pem
  description = "The private key for the master VM instance"
  sensitive   = true
}