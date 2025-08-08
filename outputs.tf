output "load_balancer_ip" {
  value = module.network.forwarding_rule_ip
}

output "instance_group_name" {
  value = module.compute.instance_group_name
}
