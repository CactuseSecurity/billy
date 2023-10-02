#!/bin/bash
echo "not finalized - do not use yet"
exit 0

#billy installer

#install required packages
echo "test"
apt-get install git ansible ssh sudo
exit

#generate ssh key
ssh-keygen -b 4096
cat .ssh/id_rsa.pub >>.ssh/authorized_keys
chmod 600 .ssh/authorized_keys

#tests
ssh 127.0.0.1
ansible -m ping 127.0.0.1

#clone repository
git clone https://github.com/CactuseSecurity/billy.git

#install billy
cd billy || exit; ansible-playbook site.yml -K
