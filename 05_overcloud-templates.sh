#!/bin/bash
mkdir -p ~/templates/environments
cat << EOF > /home/stack/templates/environments/node-info.yaml
parameter_defaults:
  OvercloudControlFlavor: baremetal
  OvercloudComputeFlavor: baremetal
  ControllerCount: 3
  ComputeCount: 2
EOF
cat << EOF > /home/stack/templates/environments/fix-nova-reserved-host-memory.yaml
parameter_defaults:
  NovaReservedHostMemory: 1024
EOF
export THT=/usr/share/openstack-tripleo-heat-templates
cp $THT/roles_data.yaml ~/templates
cp $THT/network_data.yaml ~/templates
cat << EOF > ~/templates/network_data.yaml
- name: Storage
  vip: true
  vlan: 30
  name_lower: storage
  ip_subnet: '172.18.0.0/24'
  allocation_pools: [{'start': '172.18.0.11', 'end': '172.18.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:3000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:3000::10', 'end': 'fd00:fd00:fd00:3000:ffff:ffff:ffff:fffe'}]
- name: StorageMgmt
  name_lower: storage_mgmt
  vip: true
  vlan: 40
  ip_subnet: '172.19.0.0/24'
  allocation_pools: [{'start': '172.19.0.11', 'end': '172.19.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:4000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:4000::10', 'end': 'fd00:fd00:fd00:4000:ffff:ffff:ffff:fffe'}]
- name: InternalApi
  name_lower: internal_api
  vip: true
  vlan: 20
  ip_subnet: '172.17.0.0/24'
  allocation_pools: [{'start': '172.17.0.11', 'end': '172.17.0.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:2000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:2000::10', 'end': 'fd00:fd00:fd00:2000:ffff:ffff:ffff:fffe'}]
- name: Tenant
  vip: false  # Tenant network does not use VIPs
  name_lower: tenant
  vlan: 50
  ip_subnet: '172.16.0.0/24'
  allocation_pools: [{'start': '172.16.0.11', 'end': '172.16.0.250'}]
  # Note that tenant tunneling is only compatible with IPv4 addressing at this time.
  ipv6_subnet: 'fd00:fd00:fd00:5000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:5000::10', 'end': 'fd00:fd00:fd00:5000:ffff:ffff:ffff:fffe'}]
- name: External
  vip: true
  name_lower: external
  vlan: 10
  ip_subnet: '10.0.0.0/24'
  allocation_pools: [{'start': '10.0.0.201', 'end': '10.0.0.250'}]
  gateway_ip: '10.0.0.251'
  ipv6_subnet: '2001:db8:fd00:1000::/64'
  ipv6_allocation_pools: [{'start': '2001:db8:fd00:1000::10', 'end': '2001:db8:fd00:1000:ffff:ffff:ffff:fffe'}]
  gateway_ipv6: '2001:db8:fd00:1000::1'
- name: Management
  # Management network is enabled by default for backwards-compatibility, but
  # is not included in any roles by default. Add to role definitions to use.
  enabled: true
  vip: false  # Management network does not use VIPs
  name_lower: management
  vlan: 60
  ip_subnet: '10.0.1.0/24'
  allocation_pools: [{'start': '10.0.1.4', 'end': '10.0.1.250'}]
  ipv6_subnet: 'fd00:fd00:fd00:6000::/64'
  ipv6_allocation_pools: [{'start': 'fd00:fd00:fd00:6000::10', 'end': 'fd00:fd00:fd00:6000:ffff:ffff:ffff:fffe'}]
EOF
mkdir ~/workplace
mkdir ~/output
cp -rp /usr/share/openstack-tripleo-heat-templates/* workplace
cd workplace
tools/process-templates.py -r ../templates/roles_data.yaml -n ../templates/network_data.yaml -o ../output
cd ../output
cp environments/network-environment.yaml ~/templates/environments
cd ~
sed -i 's/single-nic-vlans/multiple-nics/' templates/environments/network-environment.yaml
mkdir -p ~/templates/network/config/multiple-nics/
cp ~/output/network/config/multiple-nics/*.yaml ~/templates/network/config/multiple-nics/
sed -i 's#../../scripts/run-os-net-config.sh#/usr/share/openstack-tripleo-heat-templates/network/scripts/run-os-net-config.sh#' -i templates/network/config/multiple-nics/*.yaml
cat << EOF > ~/templates/scheduler-hints.yaml
parameter_defaults:
  ControllerSchedulerHints:
    'capabilities:node': 'controller-%index%'
  ComputeSchedulerHints:
    'capabilities:node': 'compute-%index%'
EOF
openstack baremetal node set ctrl01 --property capabilities=node:controller-0,boot_option:local
openstack baremetal node set ctrl02 --property capabilities=node:controller-1,boot_option:local
openstack baremetal node set ctrl03 --property capabilities=node:controller-2,boot_option:local
openstack baremetal node set compute01 --property capabilities=node:compute-0,boot_option:local
openstack baremetal node set compute02 --property capabilities=node:compute-1,boot_option:local
cat << EOF > ~/templates/environments/ips-from-pool-all.yaml
# Environment file demonstrating how to pre-assign IPs to all node types
resource_registry:
  OS::TripleO::Controller::Ports::ExternalPort: /usr/share/openstack-tripleo-heat-templates/network/ports/external_from_pool.yaml
  OS::TripleO::Controller::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api_from_pool.yaml
  OS::TripleO::Controller::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_from_pool.yaml
  OS::TripleO::Controller::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_mgmt_from_pool.yaml
  OS::TripleO::Controller::Ports::TenantPort: /usr/share/openstack-tripleo-heat-templates/network/ports/tenant_from_pool.yaml


  OS::TripleO::Compute::Ports::ExternalPort: /usr/share/openstack-tripleo-heat-templates/network/ports/noop.yaml
  OS::TripleO::Compute::Ports::InternalApiPort: /usr/share/openstack-tripleo-heat-templates/network/ports/internal_api_from_pool.yaml
  OS::TripleO::Compute::Ports::StoragePort: /usr/share/openstack-tripleo-heat-templates/network/ports/storage_from_pool.yaml
  OS::TripleO::Compute::Ports::StorageMgmtPort: /usr/share/openstack-tripleo-heat-templates/network/ports/noop.yaml
  OS::TripleO::Compute::Ports::TenantPort: /usr/share/openstack-tripleo-heat-templates/network/ports/tenant_from_pool.yaml


parameter_defaults:
  ControllerIPs:
    # Each controller will get an IP from the lists below, first controller, first IP
    external:
    - 10.0.0.201
    - 10.0.0.202
    - 10.0.0.203
    internal_api:
    - 172.17.0.201
    - 172.17.0.202
    - 172.17.0.203
    storage:
    - 172.18.0.201
    - 172.18.0.202
    - 172.18.0.203
    storage_mgmt:
    - 172.19.0.201
    - 172.19.0.202
    - 172.19.0.203
    tenant:
    - 172.16.0.201
    - 172.16.0.202
    - 172.16.0.203

  ComputeIPs:
    # Each compute will get an IP from the lists below, first compute, first IP
    internal_api:
    - 172.17.0.211
    - 172.17.0.212
    storage:
    - 172.18.0.211
    - 172.18.0.212
    storage_mgmt:
    - 172.19.0.211
    - 172.19.0.212
    tenant:
    - 172.16.0.211
    - 172.16.0.212

EOF
