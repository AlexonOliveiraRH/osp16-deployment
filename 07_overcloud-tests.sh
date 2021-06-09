#!/bin/bash
source ~/overcloudrc
openstack network create public \
  --external --provider-physical-network datacentre \
  --provider-network-type flat
openstack subnet create public-subnet \
  --no-dhcp --network public --subnet-range 10.0.0.0/24 \
  --allocation-pool start=10.0.0.100,end=10.0.0.200  \
  --gateway 10.0.0.1 --dns-nameserver 8.8.8.8
openstack project create eval
openstack user create user1 --project eval --password 'r3dh4t1!'
openstack role add --user user1 --project eval member
cat << EOF > user1rc
# Clear any old environment that may conflict.
for key in \$( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export NOVA_VERSION=1.1
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=user1
export OS_PROJECT_NAME=eval
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_NO_CACHE=True
export OS_CLOUDNAME=user1
export no_proxy=$no_proxy
export PYTHONWARNINGS='ignore:Certificate has no, ignore:A true SSLContext object is not available'
export OS_AUTH_TYPE=password
export OS_PASSWORD="r3dh4t1!"
export OS_AUTH_URL=$OS_AUTH_URL
export OS_IDENTITY_API_VERSION=3
export OS_COMPUTE_API_VERSION=2.latest
export OS_IMAGE_API_VERSION=2
export OS_VOLUME_API_VERSION=3
export OS_REGION_NAME=regionOne

# Add OS_CLOUDNAME to PS1
if [ -z "${CLOUDPROMPT_ENABLED:-}" ]; then
    export PS1=${PS1:-""}
    export PS1=\${OS_CLOUDNAME:+"(\$OS_CLOUDNAME)"}\ $PS1
    export CLOUDPROMPT_ENABLED=1
fi
EOF
source ~/user1rc
openstack network create private
openstack subnet create private-subnet \
  --network private \
  --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24
openstack router create router1
openstack router add subnet router1 private-subnet
openstack router set router1 --external-gateway public
source ~/overcloudrc
openstack flavor create m1.nano --vcpus 1 --ram 64 --disk 1
source ~/user1rc
openstack security group rule create --proto icmp default
openstack security group rule create --dst-port 22 --proto tcp default
curl -L -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create cirros \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare
openstack server create test-instance --flavor m1.nano --image cirros --network private
openstack floating ip create public
openstack server add floating ip test-instance 10.0.0.105
ssh cirros@10.0.0.105

