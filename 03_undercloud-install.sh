#!/bin/bash
sudo sh -c "echo 'set nu' >> /etc/vimrc"
sudo yum -y install python3-tripleoclient
cat << EOF > undercloud.conf
[DEFAULT]
undercloud_hostname = undercloud.example.com
container_images_file = containers-prepare-parameter.yaml
local_ip = 192.0.2.1/24
undercloud_public_host = 192.0.2.2
undercloud_admin_host = 192.0.2.3
undercloud_nameservers = 192.0.2.254
#undercloud_ntp_servers =
#overcloud_domain_name = example.com
subnets = ctlplane-subnet
local_subnet = ctlplane-subnet
#undercloud_service_certificate =
generate_service_certificate = true
certificate_generation_ca = local
local_interface = eth0
inspection_extras = false
undercloud_debug = false
enable_tempest = false
enable_ui = false
hieradata_override = /home/stack/hieradata.yaml

[auth]

[ctlplane-subnet]
cidr = 192.0.2.0/24
dhcp_start = 192.0.2.5
dhcp_end = 192.0.2.24
inspection_iprange = 192.0.2.100,192.0.2.120
gateway = 192.0.2.254
EOF
cat << EOF > hieradata.yaml
ironic::config::ironic_config:
  ipmi/use_ipmitool_retries:
    value: True
EOF
openstack tripleo container image prepare default   --local-push-destination   --output-env-file containers-prepare-parameter.yaml
sed -i "s/registry.redhat.io/classroom.example.com/" containers-prepare-parameter.yaml
time openstack undercloud install
