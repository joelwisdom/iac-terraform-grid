variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

# Temporary VM Instance Template
resource "google_compute_instance" "temp_instance" {
  name         = "temp-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2404-noble-amd64-v20250805"
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Wait for network to be ready
    sleep 10
    # Update and install Apache
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
    # Create a simple webpage
    echo "<h1>Welcome to $(hostname)</h1>" > /var/www/html/index.html
    # Start and enable Apache
    systemctl enable apache2
    systemctl start apache2
  EOF

  tags = ["http-server", "health-check", "allow-ssh"]
}

# Create Disk Snapshot
resource "google_compute_snapshot" "webserver" {
  name        = "webserver-snapshot"
  source_disk = google_compute_instance.temp_instance.boot_disk[0].source
  zone        = var.zone
  
  depends_on = [google_compute_instance.temp_instance]
}

# Create Custom Image from Snapshot
resource "google_compute_image" "webserver" {
  name = "webserver-image"
  
  source_snapshot = google_compute_snapshot.webserver.self_link

  depends_on = [google_compute_snapshot.webserver]
}

# Instance Template
resource "google_compute_instance_template" "webserver" {
  name         = "webserver-template"
  machine_type = "e2-micro"

  disk {
    source_image = google_compute_image.webserver.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["http-server", "health-check", "allow-ssh"]

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    startup-script = <<-EOF
      #!/bin/bash
      # Wait for network to be ready
      sleep 10
      # Update and install Apache
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y apache2
      # Create a simple webpage
      echo "<h1>Welcome to $(hostname)</h1>" > /var/www/html/index.html
      # Start and enable Apache
      systemctl enable apache2
      systemctl start apache2
    EOF
  }
}

# Instance Group Manager
resource "google_compute_instance_group_manager" "webserver" {
  name = "webserver-igm"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.webserver.self_link
  }

  named_port {
    name = "http"
    port = 80
  }

  base_instance_name = "webserver"
  target_size        = 3
}

# Get the instance group reference
data "google_compute_instance_group" "webserver" {
  name = google_compute_instance_group_manager.webserver.name
  zone = var.zone

  depends_on = [google_compute_instance_group_manager.webserver]
}
