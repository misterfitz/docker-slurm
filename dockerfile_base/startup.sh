#!/bin/bash

# Determine whether script is running as root
sudo_cmd=""
if [ "$(id -u)" != "0" ]; then
    sudo_cmd="sudo"
    sudo -k
fi

# Configure Slurm to use maximum available processors and memory
# and start required services
${sudo_cmd} bash <<SCRIPT
sed -i "s/<<HOSTNAME>>/$(hostname)/" /etc/slurm/slurm.conf
sed -i "s/<<CPU>>/$(nproc)/" /etc/slurm/slurm.conf
sed -i "s/<<MEMORY>>/$(if [[ "$(slurmd -C)" =~ RealMemory=([0-9]+) ]]; then echo "${BASH_REMATCH[1]}"; else exit 100; fi)/" /etc/slurm/slurm.conf

# Slurm 24.05+ defaults to cgroup/v2 which needs dbus (unavailable in
# containers). Use cgroup/v1 instead. Older versions ignore cgroup.conf
# if ProctrackType is not cgroup-based, so this is safe to always write.
SLURM_MAJOR=\$(slurmctld -V 2>/dev/null | grep -oP '\d+' | head -1)
if [ "\${SLURM_MAJOR:-0}" -ge 24 ]; then
    echo "CgroupPlugin=cgroup/v1" > /etc/slurm/cgroup.conf
fi

# Create runtime directories and set permissions
mkdir -p /var/run/munge /var/log/munge
chown munge:munge /var/run/munge /var/log/munge
chmod 755 /var/run/munge

# Ensure slurmctld (runs as SlurmUser=slurm) can write logs and PID
touch /var/log/slurmctld.log /var/run/slurmctld.pid
chown slurm:slurm /var/log/slurmctld.log /var/run/slurmctld.pid /var/spool/slurmctld

# Start munge (--force allows running as root in containers)
munged --force
sleep 0.5

# Start Slurm daemons
slurmctld
slurmd
sleep 1
SCRIPT

# Revoke sudo permissions
if [[ ${sudo_cmd} ]]; then
    sudo -k
fi
