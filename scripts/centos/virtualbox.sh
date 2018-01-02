#!/bin/bash

set -e
set -x

if [ "$PACKER_BUILDER_TYPE" != "virtualbox-iso" ]; then
  exit 0
fi

if [ "$(cat /etc/redhat-release)" == "CentOS release 6.8 (Final)" ]
then
sudo tee -a /etc/yum.repos.d/CentOS-Vault.repo <<-EOF

[C6.8-base]
name=CentOS-6.8 - Base
baseurl=http://vault.centos.org/6.8/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=0
EOF
elif [ "$(cat /etc/redhat-release)" == "CentOS Linux release 7.3.1611 (Core) " ]
then
sudo tee -a /etc/yum.repos.d/CentOS-Vault.repo <<-EOF

[C7.3.1611-base]
name=CentOS-7.3.1611 - Base
baseurl=http://vault.centos.org/7.3.1611/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0
EOF
fi

sudo yum -y install bzip2
sudo yum -y --enablerepo=epel install dkms
if [ "$(cat /etc/redhat-release)" == "CentOS release 6.8 (Final)" ]
then
  sudo yum -y --disablerepo="*" --enablerepo=C6.8-base install kernel-devel-$(rpm -qa|grep kernel-2|awk -F '[.-]' '{print $2"."$3"."$4"-"$5"."$6}')
elif [ "$(cat /etc/redhat-release)" == "CentOS Linux release 7.3.1611 (Core) " ]
then
  sudo yum -y --disablerepo="*" --enablerepo=C7.3.1611-base install kernel-devel-$(rpm -qa|grep kernel-3|awk -F '[.-]' '{print $2"."$3"."$4"-"$5"."$6}')
else
  sudo yum -y install kernel-devel
fi
sudo yum -y install make
sudo yum -y install perl

# Uncomment this if you want to install Guest Additions with support for X
#sudo yum -y install xorg-x11-server-Xorg

# In CentOS 6 or earlier, dkms package provides SysV init script called
# dkms_autoinstaller that is enabled by default
if systemctl list-unit-files | grep -q dkms.service; then
  sudo systemctl start dkms
  sudo systemctl enable dkms
fi

sudo mount -o loop,ro ~/VBoxGuestAdditions.iso /mnt/
sudo /mnt/VBoxLinuxAdditions.run || :
sudo umount /mnt/
rm -f ~/VBoxGuestAdditions.iso
