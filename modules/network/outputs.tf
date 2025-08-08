output "forwarding_rule_ip" {
  value = google_compute_global_forwarding_rule.http.ip_address
}
