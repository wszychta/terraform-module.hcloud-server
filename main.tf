/*
Terraform module for creating Hetzner cloud compatible user-data file
Copyright (C) 2021 Wojciech Szychta

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
locals {
  server_type_family                            = replace(var.server_type, "/[1-9]+/", "")
  changed_server_lifecycle_ignore_changes_rules = distinct(flatten([for variable in var.server_lifecycle_ignore_changes_rules : variable == "private_networks_settings" ? ["network"] : variable == "server_enable_protection" ? ["delete_protection", "rebuild_protection"] : [replace(variable, "server_", "")]]))
}

module "server_user_data_file" {
  # source = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=2.1.0"
  source                    = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=server_module_integration"
  count                     = var.external_user_data_file == null && local.server_type_family != "ccx" ? 1 : 0
  server_type               = var.server_type
  server_image              = var.server_image
  private_networks_settings = var.server_private_networks_settings
  additional_users          = var.user_data_additional_users
  additional_write_files    = var.user_data_additional_write_files
  additional_hosts_entries  = var.user_data_additional_hosts_entries
  additional_run_commands   = var.user_data_additional_run_commands
  additional_packages       = var.user_data_additional_packages
  upgrade_all_packages      = var.user_data_upgrade_all_packages
  reboot_instance           = var.user_data_reboot_instance
  timezone                  = var.user_data_timezone
  yq_version                = var.user_data_yq_version
  yq_binary                 = var.user_data_yq_binary
}

resource "hcloud_server" "server_without_lifecycle_rules" {
  count              = var.server_lifecycle_ignore_changes_rules == null ? 1 : 0
  name               = var.server_name
  server_type        = var.server_type
  image              = var.server_image
  location           = var.server_location
  datacenter         = var.server_datacenter
  ssh_keys           = var.server_ssh_keys
  keep_disk          = var.server_keep_disk
  iso                = var.server_iso
  boot_rescue_image  = var.server_boot_rescue_image
  labels             = var.server_labels
  backups            = var.server_enable_backups
  firewall_ids       = var.server_firewall_ids
  placement_group_id = var.server_placement_group_id
  delete_protection  = var.server_enable_protection
  rebuild_protection = var.server_enable_protection
  user_data          = var.external_user_data_file != null || local.server_type_family == "ccx" ? var.external_user_data_file : join("", module.server_user_data_file.*.result_file)

  dynamic "network" {
    for_each = toset(var.server_private_networks_settings)
    content {
      network_id = each.key["network_id"]
      ip         = each.key["ip"]
      alias_ips  = each.key["alias_ips"]
    }
  }
}

resource "hcloud_server" "server_with_lifecycle_rules" {
  count              = var.server_lifecycle_ignore_changes_rules != null ? 1 : 0
  name               = var.server_name
  server_type        = var.server_type
  image              = var.server_image
  location           = var.server_location
  datacenter         = var.server_datacenter
  ssh_keys           = var.server_ssh_keys
  keep_disk          = var.server_keep_disk
  iso                = var.server_iso
  boot_rescue_image  = var.server_boot_rescue_image
  labels             = var.server_labels
  backups            = var.server_enable_backups
  firewall_ids       = var.server_firewall_ids
  placement_group_id = var.server_placement_group_id
  delete_protection  = var.server_enable_protection
  rebuild_protection = var.server_enable_protection
  user_data          = var.external_user_data_file != null || local.server_type_family == "ccx" ? var.external_user_data_file : join("", module.server_user_data_file.*.result_file)

  dynamic "network" {
    for_each = toset(var.server_private_networks_settings)
    content {
      network_id = each.key["network_id"]
      ip         = each.key["ip"]
      alias_ips  = each.key["alias_ips"]
    }
  }

  lifecycle {
    ignore_changes = local.changed_server_lifecycle_ignore_changes_rules
  }
}

locals {
  final_server_id               = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.id) : join("", hcloud_server.server_with_lifecycle_rules.*.id)
  final_server_name             = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.name) : join("", hcloud_server.server_with_lifecycle_rules.*.name)
  final_server_location         = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.location) : join("", hcloud_server.server_with_lifecycle_rules.*.location)
  final_server_datacenter       = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.datacenter) : join("", hcloud_server.server_with_lifecycle_rules.*.datacenter)
  final_server_backup_windows   = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.backup_windows) : join("", hcloud_server.server_with_lifecycle_rules.*.backup_windows)
  final_server_ipv4_address     = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.ipv4_address) : join("", hcloud_server.server_with_lifecycle_rules.*.ipv4_address)
  final_server_ipv6_address     = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.ipv6_address) : join("", hcloud_server.server_with_lifecycle_rules.*.ipv6_address)
  final_server_ipv6_network     = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.ipv6_network) : join("", hcloud_server.server_with_lifecycle_rules.*.ipv6_network)
  final_server_private_networks = var.server_lifecycle_ignore_changes_rules == null ? join("", hcloud_server.server_without_lifecycle_rules.*.network) : join("", hcloud_server.server_with_lifecycle_rules.*.network)
}