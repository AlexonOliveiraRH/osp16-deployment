#!/bin/bash
sudo yum install vim tmux git -y
sudo sh -c "echo 'set nu' >> /etc/vimrc"
git clone https://AlexonOliveiraRH@github.com/AlexonOliveiraRH/osp16-deployment.git
ssh-keygen
ssh-copy-id root@undercloud.example.com
ssh root@undercloud.example.com useradd stack
ssh root@undercloud.example.com mkdir /home/stack/.ssh
ssh root@undercloud.example.com cp /root/.ssh/authorized_keys /home/stack/.ssh/
ssh root@undercloud.example.com chown -R stack:stack /home/stack/.ssh
ssh root@undercloud.example.com "echo 'stack ALL=(root) NOPASSWD:ALL' | tee -a /etc/sudoers.d/stack"
ssh root@undercloud.example.com chmod 0440 /etc/sudoers.d/stack
ssh stack@undercloud.example.com
