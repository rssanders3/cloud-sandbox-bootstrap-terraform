variable "username" {
  default = "your-username" # Replace with your SSH username
}


provider "google" {
  project = "<your-project-id>" # Replace with your Google Cloud Project ID
  region  = "us-central1"       # Adjust to your preferred region
}

resource "google_compute_network" "default" {
  name = "default-network"
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Allows SSH from any IP. Restrict this for better security.
}

resource "google_compute_instance" "vm_instance" {
  name         = "my-vm-instance"
  machine_type = "e2-medium"     # Adjust machine type based on your needs
  zone         = "us-central1-a" # Adjust zone based on your region

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # Adjust the OS as needed
    }
  }

  network_interface {
    network = google_compute_network.default.name

    access_config {
      # Ephemeral public IP to allow SSH access
    }
  }

  metadata = {
    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}"
  }
}