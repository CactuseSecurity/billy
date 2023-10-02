# Getting started with Firewall Orchestrator

## system requirements

### Hardware Requirements

Both physical and virtual systems are supported

#### For standard production installations (<1000 rules)
- 30 GB SSD 
- 8 GB RAM
- 2 CPUs

### Software Requirements

Supported operating systms: 
- Ubuntu >=20.04 (LTS only)
- Debian >=11

Recommended: Ubuntu 22.04, Debian 12

### Requirements Network Connection
- For software download during installation and upgrade:
  - Either direct Internet connection via http or https or http(s) proxy-based Internet connection.
  - In case of a security filtered Internet access, download of all required packages (operating system and base components) for installation and upgrade must be possible.
- In case of an existing support contract, remote access via ssh to all firewall orchestrator systems must be possible for Cactus eSecurity support personnel.

## Initial login web ui

- use your local browser to connect to [https://localhost/](https://localhost)
- login with username admin, the password can be found in /etc/billy/secets/ui_admin_pwd, it will also displayed at the end of the installation routine
- create additional users and assign roles (see help pages) 

## API login graphiql

- use your local browser to connect to <https://localhost:9443/api>
- login with hasura admin password found in file /etc/billy/secets/hasura_admin_pwd

## non local login

- you may also access the web UI and API remotely by replacing localhost with your systems IP address or resolvable hostname

## Using the Web Interface
Per default the system systems comes with sample data pre-installed to allow for quick testing of functionality. The sample data may be removed at any time using the "Remove sample data" buttons in the settings section.

## How to integrate your own firewall systems

Open the Web UI, head to Settings - Managements, then have a look at the help pages. 
