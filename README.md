# terraform-module.hcloud-server
## Description
<b>The purpose of this module is to provide ready to use Hetzner cloud servers with multiple network managers and cloud-init options</b>

## Supported features
- Creating Hetzner Cloud VM with all described variables inside [hcloud_server resource](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server)
- Using all `cloud-init` features described in [Hetzner User Data](https://github.com/wszychta/terraform-module.hcloud-user-data/blob/master/README.md) module
- Automatic private networks configuration in OS

## Tested vms configuration

I have tested this module on below instances types:
- CX11
- CPX11

<b>This module should also work on the rest of avaliable machines types based on avaliable documentation.</b> Please remember about [limitation for CCXxx instances type](#only-local-ssds-on-shared-resources-are-using-cloud-init-related-variables)

## Usage example

Example for Debian/Ubuntu with few packages installation:
```terraform
module "hetzner_instance" {
  source                    = "git::git@github.com:wszychta/terraform-module.hcloud-server?ref=1.0.0"
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

### After adding multiple private network interfaces some of them are not avaliable in os
I saw this behaviour twice on `debian-11` system, but <b>it may happen on all instances types and all systems</b>. The best way to prevent this issue is planning all network interfaces before instance creation, but sometimes it is not enough.

#### Affected instances types:
- `CXxx`
- `CPXxx`
- `CCXxx`

#### Solution
I saw that there are 2 ways of solving this issue. Please try them in the order I made:
1. In some cases reboot of the instance was enough - please run `reboot` command in your VM.
1. <b>(Working in most cases)</b> Please shut down instance and turn on it again. This way all network interfaces will be attached to the instance again.

Also please remember that `routes` and `nameserver` settings are applied only on instance creation, so machine must be recreated anyway when you have changed any of mentioned variables in any of the private interfaces. Please read [this manual](#changes-in-server_ssh_keys-or-user_data-are-not-forcing-instance-recreation) to know how to force instance recreation.

### Changes in server_ssh_keys or user_data are not forcing instance recreation
<b>This is expected result.</b> This is happening because `lifecycle` meta-argument cannot be used with `dynamic` meta-argument. Explanation can be found explenation [here](https://stackoverflow.com/a/62448476)

Also terraform in current version doesn't support dynamic list of `ignore_changes` lifecycle rule. There is an [issue for such feature on github](https://github.com/hashicorp/terraform/issues/3116) which I have subsribed. If Terraform maintainers will fix it, then I'm going to use it inside the module.

In my opinion both values (`ssh_keys` and `user_data`) should not force recreation of the instance if we really don't want to do this. This is why in current version of the module, both options are hardcoded.

#### Affected instances types:
- `CXxx`
- `CPXxx`
- `CCXxx`

#### Solution 
If you really need to replace instance after changing any of described values, there are two ways to do it. You can use [taint command or replace option](https://www.terraform.io/docs/cli/commands/taint.html). Example below is showing how to use both of the options
```bash
# terraform replace
terraform plan -out p.tfplan --replace='module.vm.hcloud_server.server_with_lifecycle_rules'
terraform apply p.tfplan
# terraform taint
terraform taint 'module.vm.hcloud_server.server_without_lifecycle_rules'
terraform plan -out p.tfplan
terraform apply p.tfplan
```

### Only local SSDs on shared resources are using cloud-init related variables

[Hetzner User Data](https://github.com/wszychta/terraform-module.hcloud-user-data) module was not designed to work with affected instances types. 

<b>I'm not using any of described types of instances and I'm not going to do this. I'm paing with my own money while I'm working on this module and I have no interest in using any of affected instances types</b>

Because of that variables with the prefix `user_data_*` and also private networking `routes` and `nameservers` options will be ignored when you use this module.

If you need such functionality please think about creating Pull Request for described module. You can find [developing manual in module README](https://github.com/wszychta/terraform-module.hcloud-user-data#developing).

#### Affected instances types:
- `CCXxx`

#### Solution


1. `user_data_*` variables - There is variable called `external_user_data_file` which will always be used instead of generated `cloud-init` configuration with `user_data_*` variables. In such case you need to create your own `user-data` file based on [Cloud-init modules documentation](https://cloudinit.readthedocs.io/en/latest/topics/modules.html)
1. private networking `routes` and `nameservers` options - both must be created manually after instance creation with correct network manager for choosen os type.

## Variables

| Variable name                         | variable type  | default value   | Required variable | Description |
|:-------------------------------------:|:---------------|:---------------:|:-----------------:|:-----------:|
| server_name                           | `string`       | `empty`         | <b>Yes</b>        | Name of the server to create (must be unique per project and a valid hostname as per RFC 1123) |
| server_type                           | `string`       | `empty`         | <b>Yes</b>        | Name of the server type this server should be created with. To find all avaliable options run command `hcloud server-type list` |
| server_image                          | `string`       | `empty`         | <b>Yes</b>        | Name or ID of the image the server is created from. To find all avaliable options run command `hcloud image list -o columns=name \| grep -v -w '-'` |
| server_location                       | `string`       | `null`          | <b>No</b>        | The location name to create the server in. To find all avaliable options run command `hcloud location list` |
| server_datacenter                     | `string`       | `null`          | <b>No</b>       | The datacenter name to create the server in |
| server_ssh_keys                       | `string`       | `null`          | <b>No</b>        | SSH key IDs or names which should be injected into the server at creation time` |
| server_keep_disk                      | `string`       | `false`         | <b>No</b>        | If true, do not upgrade the disk. This allows downgrading the server type later |
| server_iso                            | `string`       | `false`         | <b>No</b>        | ID or Name of an ISO image to mount |
| server_boot_rescue_image              | `string`       | `null`          | <b>No</b>        | Enable and boot in to the specified rescue system. This enables simple installation of custom operating systems. Avaliable options are: linux64 linux32 or freebsd64 |
| server_labels                         | `string`       | `null`          | <b>No</b>        | User-defined labels (key-value pairs) should be created with |
| server_enable_backups                 | `string`       | `false`         | <b>No</b>        | Enable or disable backups |
| server_firewall_ids                   | `string`       | `null`          | <b>No</b>        | Firewall IDs the server should be attached to on creation |
| server_placement_group_id             | `string`       | `null`          | <b>No</b>        | Placement Group ID the server added to on creation |
| server_enable_protection              | `string`       | `false`         | <b>No</b>        | Enable or disable delete and rebuild protection - They must be the same for now |
| server_private_networks_settings      |<pre>list(object({<br>    network_id    = string<br>    ip            = string<br>    alias_ips     = list(string)<br>    routes        = map(list(string))<br>    nameservers   = object({<br>      addresses   = list(string)<br>      search      = list(string)<br>    })<br>})</pre>| `[]` | <b>No</b> | List of configuration for all private networks.<br><b>Note:</b> Routes are defined as <b>map(list(string))</b> where key is a <b>gateway ip address</b> and list contains all <b> network destinations</b>.<br><b>Example:</b> `"192.168.0.1" = ["192.168.0.0/24","192.168.1.0/24"]` |
| user_data_additional_users            |<pre>list(object({<br>    username        = string<br>    sudo_options    = string<br>    ssh_public_keys = list(string)<br>}))</pre>| `[]` | <b>No</b> | List of additional users with their options |
| user_data_additional_write_files      |<pre>list(object({<br>    content     = string<br>    owner_user  = string<br>    owner_group = string<br>    destination = string<br>    permissions = string<br>}))</pre>| `[]` | <b>No</b> | List of additional files to create on first boot.<br><b>Note:</b> inside `content` value please provide <u><i>plain text content of the file</i></u> (not the path to the file).<br>You can use terraform to generate file from template or to read existing file from local machine |
| user_data_additional_hosts_entries    |<pre>list(object({<br>    ip        = string<br>    hostnames    = string<br>}))</pre>| `[]` | <b>No</b> | List of entries for `/etc/hosts` file. There is possibility to define multiple hostnames per single ip address |
| user_data_additional_run_commands     | `list(string)` | `[]`             | <b>No</b>         | List of additional commands to run on boot |
| user_data_additional_packages         | `list(string)` | `[]`             | <b>No</b>         | List of additional pckages to install on first boot |
| user_data_timezone                    | `string`       | `Europe/Berlin`  | <b>No</b>         | Timezone for the VM |
| user_data_upgrade_all_packages        | `bool`         | `false`          | <b>No</b>         | Set to false when there is no need to upgrade packages on first boot |
| user_data_reboot_instance             | `bool`         | `false`          | <b>No</b>         | Set to false when there is no need for instance reboot after finishing cloud-init tasks |
| user_data_yq_version                  | `string`       | `v4.6.3`         | <b>No</b>         | Version of yq script used for merging netplan script |
| user_data_yq_binary                   | `string`       | `yq_linux_amd64` | <b>No</b>         | Binary of yq script used for merging netplan script |
| external_user_data_file               | `string`       | `null`           | <b>No</b>         | external user-data file - it will be used instead of all `user_data_*` variables |

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
Please use the [issues tab](https://github.com/wszychta/terraform-module.hcloud-server/issues) to report any bugs or feature requests. 

I can't guarantee that I will work on every bug/feature, because this is my side project, but I will try to keep an eye on any created issue.

So if somebody knows how to fix any of described issues in [Known issues](#known-issues) please look into [Developing](#developing) section

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