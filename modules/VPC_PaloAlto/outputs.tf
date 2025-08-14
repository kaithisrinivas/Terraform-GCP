# The Palo Alto security policy rules that were created
/*
output "panos_security_policy_rules" {
  description = "A map of the created Palo Alto security policy rules"
  value = {
    for name, rule in panos_security_policy_rules.security_policy : name => {
      name       = rule.name
      location   = rule.location
      position   = rule.position
      source_zones = rule.source_zones
      destination_zones = rule.destination_zones
    }
  }
}
*/
output "ngfw_device" {
  description = "ngfw instance name"
  value = google_compute_instance.palo_alto_vm.hostname
}
