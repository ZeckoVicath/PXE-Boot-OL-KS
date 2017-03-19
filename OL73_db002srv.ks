#platform=x86, AMD64, or Intel EM64T
#version=DEVEL

# Install OS instead of upgrade
install

# System authorization information
auth --enableshadow --passalgo=sha512

# Use HTTP installation media
url --url http://10.0.0.80/OracleLinux_7_3/ISO

# Use graphical install
graphical
# Do not run the Setup Agent on first boot
firstboot --disable

# Specify which disks are available for partitioning
ignoredisk --only-use=xvda

# Keyboard layouts
keyboard --vckeymap=gb

# System language
lang en_GB.UTF-8

# Network information
######################################################
#################### CHANGE HERE 1/3 #################
######################################################
network  --bootproto=dhcp --device=eth0 --nameserver=10.0.0.53 --noipv6 --activate --hostname=db002srv.mydomain.tld
######################################################
#################### STOP HERE 1/3 ###################
######################################################

# Root password
rootpw --iscrypted $6$vPxV/vaOk5ngEWT0$UdkwK6mIapg5dc0W8WHEL6uaxMoH5MhVjkkzfKdwCO12apojXf9O2DBZaXovk1wcti7H4jdJHyZvPROQ/fAV61

# System services
services --enabled="chronyd"
#services --enabled="sshd"

# System timezone
timezone Europe/Luxembourg --utc --ntpservers="0.lu.pool.ntp.org","1.europe.pool.ntp.org","0.europe.pool.ntp.org"

# System bootloader configuration
bootloader --append="rhgb crashkernel=auto quiet" --location=mbr --boot-drive=xvda

# Partition information
clearpart --all --initlabel --drives=xvda

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=xvda --size=1024
part pv.007331 --fstype="lvmpv" --ondisk=xvda --grow --size=1024

# LVM information
volgroup ol_primary pv.007331 --pesize=4096
######################################################
#################### CHANGE HERE 2/3 #################
######################################################
logvol /var/log --vgname=ol_primary --fstype="xfs" --size=2048 --name=var_log --maxsize=5120 --grow
logvol swap --vgname=ol_primary --fstype="swap" --size=2048 --name=swap
logvol / --vgname=ol_primary --fstype="xfs" --size=1024 --name=root --grow
######################################################
#################### STOP HERE 2/3 ###################
######################################################

# SELinux configuration
selinux --enforcing

# Installation logging level
logging --level=info

# Firewall configuration
firewall --enabled --service=ssh

# Additional YUM repos for unbreakeable kernel
repo --name="Server-HighAvailability" --baseurl=file:///run/install/repo/addons/HighAvailability
repo --name="Server-ResilientStorage" --baseurl=file:///run/install/repo/addons/ResilientStorage
repo --name="Server-Mysql" --baseurl=file:///run/install/repo/addons/Mysql

# Reboot after success install
reboot

#Packages to install
%packages
@^minimal
@core
chrony
kexec-tools
openscap
openscap-scanner
scap-security-guide
lsof
bind-utils
vim
#add more packages here
%end

# Security Profiles to install
%addon org_fedora_oscap
    content-type = scap-security-guide
    profile = pci-dss
%end

# Kernel Dump Strategy
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

# Password Strength Rules
%anaconda
pwpolicy root --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy luks --minlen=6 --minquality=50 --notstrict --nochanges --notempty
%end

# Adding Server to network and joining puppet
%post --log=/root/my-post-log
echo
echo "##############################"
echo "# Running Post Configuration #"
echo "##############################"
echo
echo
echo "#################################"
echo "# Setting Network Configuration #"
echo "#################################"
echo
# Network Interface
grep -q '^IPV6INIT' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^IPV6INIT.*/IPV6INIT="no"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'IPV6INIT="no"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^DNS1' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^DNS1.*/DNS1="10.0.0.53"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'DNS1="10.0.0.53"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^DNS2' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^DNS1.*/DNS1="10.0.0.54"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'DNS1="10.0.0.54"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^BOOTPROTO' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^BOOTPROTO.*/BOOTPROTO="none"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'BOOTPROTO="none"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^DEVICE' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^DEVICE.*/DEVICE="eth0"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'DEVICE="eth0"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^ONBOOT' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^ONBOOT.*/ONBOOT="yes"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'ONBOOT="yes"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
######################################################
#################### CHANGE HERE 3/3 #################
######################################################
grep -q '^DHCP_HOSTNAME' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^DHCP_HOSTNAME.*/DHCP_HOSTNAME="db002srv.mydomain.tld"/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'DHCP_HOSTNAME="db002srv.mydomain.tld"' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^IPADDR' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^IPADDR.*/IPADDR=10.0.0.231/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'IPADDR=10.0.0.231' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^NETMASK' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^NETMASK.*/NETMASK=255.255.255.0/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-eth0
grep -q '^GATEWAY' /etc/sysconfig/network-scripts/ifcfg-eth0 && sed -i 's/^GATEWAY.*/GATEWAY=10.0.0.254/' /etc/sysconfig/network-scripts/ifcfg-eth0 || echo 'GATEWAY=10.0.0.254' >> /etc/sysconfig/network-scripts/ifcfg-eth0
######################################################
#################### STOP HERE 3/3 ###################
######################################################
echo
echo "#############################"
echo "# Setting DNS Configuration #"
echo "#############################"
echo
# DNS
grep -q '^domain' /etc/resolv.conf && sed -i 's/^domain.*/domain mydomain.tld/' /etc/resolv.conf || echo 'domain mydomain.tld' >> /etc/resolv.conf
grep -q '^nameserver' /etc/resolv.conf && sed -i 's/^nameserver.*/nameserver 10.0.0.53/' /etc/resolv.conf || echo 'nameserver 10.0.0.53' >> /etc/resolv.conf
grep -v '^nameserver 10.0.0.54' /etc/resolv.conf && echo 'nameserver 10.0.0.54' >> /etc/resolv.conf
echo
echo "#####################"
echo "# Installing Puppet #"
echo "#####################"
echo
# Puppet
yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && yum -y install puppet
echo
echo "#################################"
echo "# Setting Puppet up and running #"
echo "#################################"
echo
echo "server = 'foreman001srv.mydomain.tld'" >> /etc/puppetlabs/puppet/puppet.conf
systemctl enable puppet
systemctl start puppet
/opt/puppetlabs/puppet/bin/puppet agent -t
echo
echo "########"
echo "# Done #"
echo "########"
echo
%end
