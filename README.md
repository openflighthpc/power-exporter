# Power Exporter
Service written in Ruby to collect power metrics from physical hardware over IPMI / SNMP and export them in Prometheus style metrics via a simple `Net::HTTP::Server` . Integrates with schedulers (Slurm, PBS, GridEngine and Openstack) to provide a `state` label on the exported power metrics.

Example metrics:
```
node_power_usage{node="master1", type="core", rack="1"} 264.0
node_power_usage{node="master2", type="core", rack="1"} 264.0
node_power_usage{node="node01", type="compute", rack="1", state="allocated"} 528.0
node_power_usage{node="node02", type="compute", rack="1", state="allocated"} 552.0
node_power_usage{node="node03", type="compute", rack="1", state="allocated"} 504.0
node_power_usage{node="node04", type="compute", rack="1", state="allocated"} 528.0
node_power_usage{node="node05", type="compute", rack="1", state="allocated"} 528.0
node_power_usage{node="node06", type="compute", rack="1", state="allocated"} 528.0
```

## Prerequisites
- Git
- Ruby (tested with v2.7.1)
- Ruby `bundle`
- SSH key access for the daemon user to:
  - Scheduler hosts (as required).
  - Any hosts using the `ipmi_ssh` collection method.
- IPMI-over-lan enabled for any hosts using the `ipmi` collection method.
- SNMPv2 enabled and configured with a read community string for any hosts using the `snmpv2` collection method.
- SNMPv3 enabled and configured with a user and `noAuthNoPriv` for any hosts using the `snmpv3` collection method.

## Installation
Clone this git repository and checkout the desired branch / release.
```
git clone
git checkout <branch/release>
```

Run the installation script. The installation will install to `/opt/power-exporter` - if you wish to install elsewhere you will need to update the install script and service file as appropriate.
```
cd power-exporter
bash install.sh
```

Set the user and group to run the service as. If your Ruby binary is not in the default path `/usr/bin/ruby`, also update this to the correct path.
```
vim /usr/lib/systemd/system/power-exporter.service
systemctl daemon-reload
```
Install the required Ruby gems.
```
cd /opt/power-exporter
/path/to/bundle install
```

Create an SSH key in `/opt/power-exporter/etc/id_powerexporter` for the exporter to use. The public key will need to be added to the `authorized_keys` file of the same user on the relevant hosts.
```
ssh-keygen -q -t rsa -N '' -f /opt/power-exporter/etc/id_powerexporter
```

Configure `/opt/power-exporter/etc/config.yaml` - an example configuration file is provided with a brief explanation of the various configuration parameters.

Minimal configuration example:
```
scheduler:
  noop:
    enabled: true
  slurm:
    enabled: true
    schedulers:
      infra02:
        sinfo_bin: /usr/bin/sinfo
methods:
  ipmi:
    user: admin
    password: password
  snmpv2:
    community: public
  snmpv3:
    username: admin
logging:
  path: log/power-exporter.log
exporter:
  port: 9106
  ssh_key: etc/id_powerexporter
```

Configure `/opt/power-exporter/etc/nodes.yaml` - an example file is provided with various examples and a brief explanation of the various configuration parameters.

Minimal nodes example:
```
master1:
  method: snmpv2
  host: 10.11.10.11
  type: core
  rack: 1
  oids:
    - 1.3.6.1.4.1.674.10892.5.4.600.30.1.6.1.3
node01:
  method: snmpv2
  host: 10.11.1.1
  type: compute
  scheduler: slurm
  rack: 1
  oids:
    - 1.3.6.1.4.1.674.10892.5.4.600.30.1.6.1.3
node02:
  method: snmpv2
  host: 10.11.1.2
  type: compute
  scheduler: slurm
  rack: 1
  oids:
    - 1.3.6.1.4.1.674.10892.5.4.600.30.1.6.1.3
```
Enable and start the service
```
systemctl daemon-reload
systemctl enable --now power-exporter
```

## Known Issues / Future Enhancements
Currently the exporter is configured to collect power readings from every host each time it is scraped. This has multiple issues:

- BMCs are notoriously slow and multiple concurrent requests can have unexpected behaviour / cause them to crash.
- Each reading is collected in serial, resulting in very slow scrape times for large numbers of hosts.
- This is further exacerbated by non-responsive hosts that need to hit a time out.

Future work would look to rewrite the exporter into two separate threads:
- A collector, responsible for collecting and caching the power metrics. This could potentially also be multi-threaded to provide better performance.
- An exporter, responsible for exposing the latest cached power metrics.

Whilst the Openstack integration uses the Openstack API to lookup the state of the node, the remaining schedulers (Slurm, GridEngine and PBS) currently run various `sinfo` / `qstat` commands on a remote host via `ssh`. This requires SSH keys between the server running the exporter and the target scheduler host, and is reliant on the output format of the various commands.

Slurm for example has a a REST API that could potentially be used. PBS and GridEngine would require further investigation.
