#!/bin/bash
source stackrc
mkdir images && \
mkdir -p templates/environments && \
sudo yum -y install rhosp-director-images && \
tar -C images -xvf /usr/share/rhosp-director-images/overcloud-full-latest.tar && \
tar -C images -xvf /usr/share/rhosp-director-images/ironic-python-agent-latest.tar && \
openstack overcloud image upload --image-path ~/images && \
openstack image list && \
cat << EOF > nodes.json
{
    "nodes": [
        {
            "mac": [
                "2c:c2:60:01:02:02"
            ],
            "name": "ctrl01",
            "pm_addr": "192.0.2.221",
            "pm_password": "redhat",
            "pm_type": "pxe_ipmitool",
            "pm_user": "admin"
        },
        {
            "mac": [
                "2c:c2:60:01:02:03"
            ],
            "name": "ctrl02",
            "pm_addr": "192.0.2.222",
            "pm_password": "redhat",
            "pm_type": "pxe_ipmitool",
            "pm_user": "admin"
        },
        {
            "mac": [
                "2c:c2:60:01:02:04"
            ],
            "name": "ctrl03",
            "pm_addr": "192.0.2.223",
            "pm_password": "redhat",
            "pm_type": "pxe_ipmitool",
            "pm_user": "admin"
        },
        {
            "mac": [
                "2c:c2:60:01:02:05"
            ],
            "name": "compute01",
            "pm_addr": "192.0.2.224",
            "pm_password": "redhat",
            "pm_type": "pxe_ipmitool",
            "pm_user": "admin"
        },
        {
            "mac": [
                "2c:c2:60:01:02:06"
            ],
            "name": "compute02",
            "pm_addr": "192.0.2.225",
            "pm_password": "redhat",
            "pm_type": "pxe_ipmitool",
            "pm_user": "admin"
        }
    ]
}
EOF
openstack overcloud node import --validate-only ~/nodes.json
openstack overcloud node import --introspect --provide nodes.json
openstack baremetal node list
openstack baremetal introspection list
