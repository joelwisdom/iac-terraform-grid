variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "grid-capstone-467613"
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "webserver-network"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Replace with your specific IP ranges
}
