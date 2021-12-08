# terraform-module.hcloud-server
## Description
<b>The purpose of this module is to provide ready to use Hetzner cloud servers with multiple network managers and cloud-init options</b>

## Supported features
- Creating Hetzner Cloud VM with all described variables inside [hcloud_server resource](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server)
- Using all `cloud-init` features described in [Hetzner User Data](https://github.com/wszychta/terraform-module.hcloud-user-data/blob/master/README.md) module
- This module supports `ignore_changes` lifecycle rule

## Unsupported features
- Creating Private networks for VM - Please read more [here](#module-is-not-creating-private-network-interfaces)

## Tested vms configuration

I have tested this module on below instances types:
- CX11
- CPX11

<b>This module should also work on the rest of avaliable machines types based on avaliable documentation.</b>

## Usage example

Example for Debian/Ubuntu with few packages installation:
```terraform
module "hetzner_instance" {
  source                    = "git::git@github.com:wszychta/terraform-module.hcloud-server?ref=tags/1.0.0"
  server_name               = "testing_vm"
  server_type               = "cpx11"
  server_image              = "ubuntu-20.04"
  server_private_networks_settings = [
    {
      network_id = hcloud_network.network.id
      ip         = "192.168.2.5"
      alias_ips  = [
        "192.168.2.6",
        "192.168.2.7"
      ]
      routes = {
        "192.168.0.1" = [
          "192.168.0.0/24",
          "192.168.1.0/24"
        ]
      }
      nameservers = {
        addresses = [
          "192.168.0.3"
        ]
        search = [
          "lab.net",
        ]
      }
    }
  ]
  
  user_data_additional_users  = [
    {
      username = "local"
      sudo_options = "ALL=(ALL) NOPASSWD:ALL"
      ssh_public_keys = [
        "ssh-rsa ..................."
      ]
    }
  ]
  user_data_additional_hosts_entries = [
    {
      ip = "192.168.0.4"
      hostnames = [
        "host1.lab.net",
        "host1"
      ]
    },
    {
      ip = "192.168.0.5"
      hostnames = [
        "host2.lab.net",
        "host2"
      ]
    },
  ]
  user_data_additional_run_commands = [
    "echo 'test command'"
  ]
  user_data_additional_run_commands = [
    "htop",
    "telnet",
    "nano"
  ]
}
```

## Known Issues

### Module is not creating private network interfaces
The order of creating private network interfaces is really important.e. It <b>must be</b> the same as defined in `user_data_private_networks_settings` variable.
[Hetzner User Data](https://github.com/wszychta/terraform-module.hcloud-user-data) is generating files before instance creation, because of that we are unable to determine interface number dynamically when instance is up and running.
If the order of network interfaces will be different than in `user_data_private_networks_settings` variable there is possibility that <b>instance will be unreachable after first reboot</b>.

This is why I haven't added support for creating private newtork interfaces inside this module.

#### Affected instances types:
- `CXxx`
- `CPXxx`
- `CCXxx`

#### Solution
To create network interfaces in correct order you need to use meta-argument [depends_on](https://www.terraform.io/docs/language/meta-arguments/depends_on.html). This is forcing terraform to create resource only after other resource was created.
Below terraform example presents how to do this with this module:
```terraform
resource "hcloud_server_network" "vm_private_ip_1" {
  server_id  = module.hetzner_instance.server_id
  network_id = data.hcloud_network.private_network.id
  ip         = "desired_IP_address"
}

resource "hcloud_server_network" "vm_private_ip_2" {
  server_id  = module.hetzner_instance.server_id
  network_id = data.hcloud_network.private_network.id
  ip         = "desired_IP_address"

  depends_on = [
    hcloud_server_network.vm_private_ip_1
  ]
}
```

### Adding lifecycle records forces replacement of the VM
<b>This is expected result.</b> This is happening because `lifecycle` meta-argument cannot be used with `dynamic` meta-argument. Explanation can be found explenation [here](https://stackoverflow.com/a/62448476)

#### Affected instances types:
- `CXxx`
- `CPXxx`
- `CCXxx`

#### Solution 
You must move instance terraform state like in example below. This is the only way to prevent recreation of the instance.
```bash
terraform state mv 'module.vm.hcloud_server.server_without_lifecycle_rules' 'module.vm.hcloud_server.server_with_lifecycle_rules' # when there is a need to add lifecycle ignore_changes rules
terraform state mv 'module.vm.hcloud_server.server_with_lifecycle_rules' 'module.vm.hcloud_server.server_without_lifecycle_rules' # when there is a need to remove lifecycle ignore_changes rules
```

### Only local SSDs on shared resources are using cloud-init related variables

[Hetzner User Data](https://github.com/wszychta/terraform-module.hcloud-user-data) module was not designed to to work with affected instances types. 

<b>I'm not using any of described types of instances and I'm not going to do this. I'm paing with my own money while I'm working on this module and I have no interest in using any of affected instances types</b>

Because of that below list of variables will be ignored when you use this module:

If you need such functionality please think about creating Pull Request for described module. You can find [developing manual in module README](https://github.com/wszychta/terraform-module.hcloud-user-data#developing).

#### Affected instances types:
- `CCXxx`

#### Solution

There is variable called `external_user_data_file` which will always be used instead of generated `cloud-init` configuration with `user_data_*` variables. In such case you need to create your own `user-data` file based on [Cloud-init modules documentation](https://cloudinit.readthedocs.io/en/latest/topics/modules.html)

## Variables

| Variable name                         | variable type  | default value   | Required variable | Description |
|:-------------------------------------:|:---------------|:---------------:|:-----------------:|:-----------:|
| server_name                           | `string`       | `empty`         | <b>Yes</b>        | Name of the server to create (must be unique per project and a valid hostname as per RFC 1123) |
| server_type                           | `string`       | `empty`         | <b>Yes</b>        | Name of the server type this server should be created with. To find all avaliable options run command `hcloud server-type list` |
| server_image                          | `string`       | `empty`         | <b>Yes</b>        | Name or ID of the image the server is created from. To find all avaliable options run command `hcloud image list -o columns=name | grep -v -w '-'` |
| server_location                       | `string`       | `empty`         | <b>No</b>        | The location name to create the server in. To find all avaliable options run command `hcloud location list` |
| server_datacenter                     | `string`       | `empty`         | <b>No</b>       | The datacenter name to create the server in |
| server_ssh_keys                       | `string`       | `empty`         | <b>No</b>        | SSH key IDs or names which should be injected into the server at creation time` |
| server_keep_disk                      | `string`       | `empty`         | <b>No</b>        | If true, do not upgrade the disk. This allows downgrading the server type later |
| server_iso                            | `string`       | `empty`         | <b>No</b>        | ID or Name of an ISO image to mount |
| server_boot_rescue_image              | `string`       | `empty`         | <b>No</b>        | Enable and boot in to the specified rescue system. This enables simple installation of custom operating systems. Avaliable options are: linux64 linux32 or freebsd64 |
| server_labels                         | `string`       | `empty`         | <b>No</b>        | User-defined labels (key-value pairs) should be created with |
| server_enable_backups                 | `string`       | `empty`         | <b>No</b>        | Enable or disable backups |
| server_firewall_ids                   | `string`       | `empty`         | <b>No</b>        | Firewall IDs the server should be attached to on creation |
| server_placement_group_id             | `string`       | `empty`         | <b>No</b>        | Placement Group ID the server added to on creation |
| server_enable_protection              | `string`       | `empty`         | <b>No</b>        | Enable or disable delete and rebuild protection - They must be the same for now |
| server_private_networks_settings      |<pre>list(object({<br>    network_id    = string<br>    ip            = string<br>    alias_ips     = list(string)<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> | List of configuration for all private networks.<br><b>Note:</b> Routes are defined as <b>map(list(string))</b> where key is a <b>gateway ip address</b> and list contains all <b> network destinations</b>.<br><b>Example:</b> `"192.168.0.1" = ["192.168.0.0/24","192.168.1.0/24"]` |
| server_lifecycle_ignore_changes_rules | `list(string)` | `[]`             | <b>No</b>         | List of `ignore_changes` lifecycle meta-argument variables |
| user_data_additional_users            |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| user_data_additional_write_files      |<pre>list(object({<br>    content     = string<br>    owner_user  = string<br>    owner_group = string<br>    destination = string<br>    permissions = string<br>}))</pre>| `[]` | <b>No</b> | List of additional files to create on first boot.<br><b>Note:</b> inside `content` value please provide <u><i>plain text content of the file</i></u> (not the path to the file).<br>You can use terraform to generate file from template or to read existing file from local machine |
| user_data_additional_hosts_entries    |<pre>list(object({<br>    ip        = string<br>    hostnames    = string<br>}))</pre>| `[]` | <b>No</b> | List of entries for `/etc/hosts` file. There is possibility to define multiple hostnames per single ip address |
| user_data_additional_run_commands     | `list(string)` | `[]`             | <b>No</b>         | List of additional commands to run on boot |
| user_data_additional_packages         | `list(string)` | `[]`             | <b>No</b>         | List of additional pckages to install on first boot |
| user_data_timezone                    | `string`       | `Europe/Berlin`  | <b>No</b>         | Timezone for the VM |
| user_data_upgrade_all_packages        | `bool`         | `true`           | <b>No</b>         | Set to false when there is no need to upgrade packages on first boot |
| user_data_reboot_instance             | `bool`         | `true`           | <b>No</b>         | Set to false when there is no need for instance reboot after finishing cloud-init tasks |
| user_data_yq_version                  | `string`       | `v4.6.3`         | <b>No</b>         | Version of yq script used for merging netplan script |
| user_data_yq_binary                   | `string`       | `yq_linux_amd64` | <b>No</b>         | Binary of yq script used for merging netplan script |
| external_user_data_file               | `string`       | `empty`          | <b>No</b>         | external user-data file - it will be used instead of all `user_data_*` variables |

## Outputs

| Output name             | Description |
|:-----------------------:|:------------|
| server_id               | Server ID |
| server_name             | Server name |
| server_location         | The name of the location used for this instance |
| server_datacenter       | The name of the datacenter used for this instance |
| server_backup_window    | Backup window time if backup option was enabled |
| server_ipv4_address     | Server IPv4 Public Address |
| server_ipv6_address     | Server IPv6 Public Address |
| server_ipv6_network     | Server IPv6 Network |
| server_private_networks | Output of the `network` variable with private networks details |
| result_user_data_file   | Result cloud-config file which will be used by instance (depending on provided `server_image` variable) |

## Contributing
### Bug Reports/Feature Requests
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-user-data/issues) to report any bugs or feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.

So if somebody knows how to fix any of described issues in [Known issues](#known-issues) please look into [Developing](https://github.com/wszychta/terraform-module.hcloud-user-data/tree/initial_commit#developing) section

### Supporting development
If you like this module and you haven't started working with Hetzner Cloud you can use my [PERSONAL REFERRAL LINK](https://hetzner.cloud/?ref=YQhSB5WwTzqt) to start working with Hetzner cloud.
You will get 20 Euro on start and after spending additional 10 Euro I will get the same amount of money.

### Developing
If you have and idea how to improve this module please:
1. Fork this module from `master` branch
2. Work on your changes inside your fork
3. Create Pull Request on this respository.
4. In my spare time I will look at proposed changes

## Copyright 
Copyright © 2021 Wojciech Szychta

## License
GNU GENERAL PUBLIC LICENSE Version 3