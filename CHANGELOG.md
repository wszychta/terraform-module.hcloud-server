# 1.1.0
## Main changes
- Add support for public IPv4 and IPv6 addresses configuration
## Breaking Changes
- Removal of `server_location` variable - using both `location` and `datacenter` variables is not allowed for servers and `datacenter` is the only allowed variable for `hcloud_primary_ip` resource

# 1.0.2
## Main changes
- Describe private network order issue

# 1.0.1
## Main changes
- Fix Netplan images private networking

# 1.0.0
## Main changes
- Initial version of the module - Please read [README](README.md) for all details