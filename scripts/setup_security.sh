#!/bin/bash

log "$GREEN" "Applying additional security measures..."
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

log "$GREEN" "Disabling unused network protocols..."
echo "install dccp /bin/true" >> /etc/modprobe.d/disable-protocols.conf
echo "install sctp /bin/true" >> /etc/modprobe.d/disable-protocols.conf
echo "install rds /bin/true" >> /etc/modprobe.d/disable-protocols.conf
echo "install tipc /bin/true" >> /etc/modprobe.d/disable-protocols.conf

log "$GREEN" "Setting up log rotation..."
apt-get install -y logrotate

log "$GREEN" "Configuring system auditing..."
apt-get install -y auditd
systemctl enable auditd
systemctl start auditd