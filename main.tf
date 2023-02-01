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
locals {
  server_type_family = replace(var.server_type, "/[1-9]+/", "")
}

module "server_user_data_file" {
  source                    = "git::git@github.com:wszychta/terraform-module.hcloud-user-data?ref=2.2.1"
  count                     = var.external_user_data_file == null && local.server_type_family != "ccx" ? 1 : 0
  server_type               = var.server_type
  server_image              = var.server_image
  private_networks_only     = var.server_enable_public_ipv4 || var.server_enable_public_ipv6 || var.server_public_ipv4_id != null || var.server_public_ipv6_id != null ? false : true
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

resource "hcloud_primary_ip" "v4" {
  count             = var.server_enable_public_ipv4 && var.server_public_ipv4_id == null ? 1 : 0
  name              = "${var.server_name}-public-ipv4"
  datacenter        = var.server_datacenter
  type              = "ipv4"
  assignee_type     = "server"
  auto_delete       = var.server_auto_delete_public_ips
  delete_protection = var.server_enable_protection
  labels            = var.server_labels
}

resource "hcloud_primary_ip" "v6" {
  count             = var.server_enable_public_ipv6 && var.server_public_ipv4_id == null ? 1 : 0
  name              = "${var.server_name}-public-ipv6"
  datacenter        = var.server_datacenter
  type              = "ipv6"
  assignee_type     = "server"
  auto_delete       = var.server_auto_delete_public_ips
  delete_protection = var.server_enable_protection
  labels            = var.server_labels
}

resource "hcloud_server" "server_with_lifecycle_rules" {
  name                    = var.server_name
  server_type             = var.server_type
  image                   = var.server_image
  allow_deprecated_images = var.allow_deprecated_images
  datacenter              = var.server_datacenter
  ssh_keys                = var.server_ssh_keys
  keep_disk               = var.server_keep_disk
  iso                     = var.server_iso
  rescue                  = var.server_boot_rescue_image
  labels                  = var.server_labels
  backups                 = var.server_enable_backups
  firewall_ids            = var.server_enable_public_ipv4 || var.server_enable_public_ipv6 || var.server_public_ipv4_id != null || var.server_public_ipv6_id != null ? var.server_firewall_ids : null
  placement_group_id      = var.server_placement_group_id
  delete_protection       = var.server_enable_protection
  rebuild_protection      = var.server_enable_protection
  user_data               = var.external_user_data_file != null || local.server_type_family == "ccx" ? var.external_user_data_file : join("", module.server_user_data_file.*.result_file)

  public_net {
    ipv4_enabled = var.server_public_ipv4_id == null ? var.server_enable_public_ipv4 : true
    ipv4         = var.server_enable_public_ipv4 ? var.server_public_ipv4_id == null ? one(hcloud_primary_ip.v4[*].id) : var.server_public_ipv4_id : null
    ipv6_enabled = var.server_public_ipv4_id == null ? var.server_enable_public_ipv6 : true
    ipv6         = var.server_enable_public_ipv6 ? var.server_public_ipv6_id == null ? one(hcloud_primary_ip.v6[*].id) : var.server_public_ipv6_id : null
  }

  dynamic "network" {
    for_each = var.server_private_networks_settings
    content {
      network_id = network.value["network_id"]
      ip         = network.value["ip"]
      alias_ips  = network.value["alias_ips"]
    }
  }

  lifecycle {
    ignore_changes = [
      ssh_keys,
      user_data
    ]
  }
}