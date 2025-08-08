output "instance_group" {
  value = data.google_compute_instance_group.webserver.self_link
}

output "instance_group_name" {
  value = google_compute_instance_group_manager.webserver.name
}
