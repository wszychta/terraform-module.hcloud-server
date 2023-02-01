/*
Terraform module for creating Hetzner cloud compatible user-data file
Copyright (C) 2023 Wojciech Szychta

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
output "server_id" {
  value       = hcloud_server.server_with_lifecycle_rules.id
  description = "Server ID"
}

output "server_name" {
  value       = hcloud_server.server_with_lifecycle_rules.name
  description = "Server name"
}

output "server_location" {
  value       = hcloud_server.server_with_lifecycle_rules.location
  description = "The name of the location used for this instance"
}

output "server_datacenter" {
  value       = hcloud_server.server_with_lifecycle_rules.datacenter
  description = "The name of the datacenter used for this instance"
}

output "server_backup_window" {
  value       = hcloud_server.server_with_lifecycle_rules.backup_window
  description = "Backup window time if backup option was enabled"
}

output "server_ipv4_address" {
  value       = hcloud_server.server_with_lifecycle_rules.ipv4_address
  description = "Server IPv4 Public Address"
}

output "server_ipv6_address" {
  value       = hcloud_server.server_with_lifecycle_rules.ipv6_address
  description = "Server IPv6 Public Address"
}

output "server_ipv6_network" {
  value       = hcloud_server.server_with_lifecycle_rules.ipv6_network
  description = "Server IPv6 Network"
}

output "server_private_networks" {
  value       = hcloud_server.server_with_lifecycle_rules.network
  description = "Output of the `network` variable with private networks details"
}

output "result_user_data_file" {
  value       = var.external_user_data_file != null || local.server_type_family == "ccx" ? var.external_user_data_file : join("", module.server_user_data_file.*.result_file)
  description = "Result cloud-config file which will be used by instance"
}