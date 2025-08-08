variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges"
  type        = list(string)
}

variable "instance_group" {
  description = "The self link of the instance group manager"
  type        = string
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
}

# Firewall Rule
resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.allowed_ip_ranges
  target_tags   = ["http-server"]
}

# SSH Firewall Rule
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Or replace with your specific IP
  target_tags   = ["allow-ssh"]
}

# Health Check Firewall Rule
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["health-check"]
}

# Health Check
resource "google_compute_health_check" "http" {
  name                = "${var.network_name}-http-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Backend Service
resource "google_compute_backend_service" "backend" {
  name        = "${var.network_name}-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  backend {
    group           = var.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.http.id]
  enable_cdn    = false
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = "${var.network_name}-url-map"
  default_service = google_compute_backend_service.backend.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.network_name}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.network_name}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "backend_service" {
  value = google_compute_backend_service.backend.self_link
}
