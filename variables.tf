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
variable "server_name" {
  type        = string
  description = "(Required) Name of the server to create (must be unique per project and a valid hostname as per RFC 1123)"
}

variable "server_type" {
  type        = string
  description = "(Required) Name of the server type this server should be created with. To find all avaliable options run command `hcloud server-type list`"
}

variable "server_image" {
  type        = string
  description = "(Required) Name or ID of the image the server is created from. To find all avaliable options run command `hcloud image list -o columns=name | grep -v -w '-'`"
}

variable "server_location" {
  type        = string
  description = "The location name to create the server in. To find all avaliable options run command `hcloud location list`"
  default     = null
}

variable "server_datacenter" {
  type        = string
  description = "The datacenter name to create the server in"
  default     = null
}

variable "server_ssh_keys" {
  type        = list(string)
  description = "SSH key IDs or names which should be injected into the server at creation time"
  default     = null
}

variable "server_keep_disk" {
  type        = bool
  description = "If true, do not upgrade the disk. This allows downgrading the server type later"
  default     = false
}

variable "server_iso" {
  type        = string
  description = "ID or Name of an ISO image to mount"
  default     = null
}

variable "server_boot_rescue_image" {
  type        = string
  description = "Enable and boot in to the specified rescue system. This enables simple installation of custom operating systems. Avaliable options are: linux64 linux32 or freebsd64"
  default     = null
}

variable "server_labels" {
  type        = map(string)
  description = "User-defined labels (key-value pairs) should be created with"
  default     = null
}

variable "server_enable_backups" {
  type        = bool
  description = "Enable or disable backups"
  default     = false
}

variable "server_firewall_ids" {
  type        = list(string)
  description = "Firewall IDs the server should be attached to on creation"
  default     = null
}

variable "server_placement_group_id" {
  type        = string
  description = "Placement Group ID the server added to on creation"
  default     = null
}

variable "server_enable_protection" {
  type        = bool
  description = "Enable or disable delete and rebuild protection - They must be the same for now"
  default     = false
}

variable "server_private_networks_settings" {
  type = list(object(
    {
      network_id = string
      ip         = string
      alias_ips  = list(string)
      routes     = map(list(string))
      nameservers = object(
        {
          addresses = list(string)
          search    = list(string)
        }
      )
    }
  ))
  default = []
}

variable "user_data_additional_users" {
  type = list(object({
    username        = string
    sudo_options    = string
    ssh_public_keys = list(string)
  }))
  default = []
}

variable "user_data_additional_write_files" {
  type = list(object({
    content     = string
    owner_user  = string
    owner_group = string
    destination = string
    permissions = string
  }))
  default = []
}

variable "user_data_additional_hosts_entries" {
  type = list(object({
    ip        = string
    hostnames = list(string)
  }))
  default = []
}

variable "user_data_additional_run_commands" {
  type    = list(string)
  default = []
}

variable "user_data_additional_packages" {
  type    = list(string)
  default = []
}

variable "user_data_upgrade_all_packages" {
  type    = bool
  default = false
}

variable "user_data_reboot_instance" {
  type    = bool
  default = false
}

variable "user_data_timezone" {
  type    = string
  default = "Europe/Berlin"
}

variable "user_data_yq_version" {
  type    = string
  default = "v4.6.3"
}

variable "user_data_yq_binary" {
  type    = string
  default = "yq_linux_amd64"
}

variable "external_user_data_file" {
  type        = string
  description = "This user_data file will be used in new vm instead of the one generated with the module"
  default     = null
}