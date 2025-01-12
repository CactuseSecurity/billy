# openldap_server

This roles installs the OpenLDAP server on the target machine. It has the
option to enable/disable SSL by setting it in defaults or overriding it.

## Requirements

This role requires Ansible 1.4 or higher, and platform requirements are listed
in the metadata file.

## Role Variables

The variables that can be passed to this role and a brief description about
them are as follows:

```console
openldap_serverdomain_name: billy.internal    # The domain prefix for ldap
openldap_serverrootpw:                         # The password for admin user (Manager) for openldap is now randomly generated
openldap_serverenable_ssl: true                # To enable/disable ssl for the ldap
openldap_servercountry: US                     # The self signed ssl certificate parameters
openldap_serverstate: Oregon
openldap_serverlocation: Portland
openldap_serverorganization: IT
```

## Example: Configure an OpenLDAP server with SSL

```yaml
- hosts: all
  sudo: true
  roles:
  - role: openldap_server
    openldap_server_domain_name: billy.internal
    openldap_server_rootpw: <randomly generated>
    openldap_server_enable_ssl: true
    openldap_server_country: US
    openldap_server_state: Oregon
    openldap_server_location: Portland
    openldap_server_organization: IT
```

## Dependencies

None

## License

BSD

## Author Information

Benno Joy
