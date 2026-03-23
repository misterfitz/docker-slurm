#!/bin/bash
set -e

# Configure Slurm: hostname, CPUs, memory
sed -i "s/<<HOSTNAME>>/$(hostname)/" /etc/slurm/slurm.conf
sed -i "s/<<CPU>>/$(nproc)/" /etc/slurm/slurm.conf

REAL_MEM=$(slurmd -C 2>/dev/null | grep -oP 'RealMemory=\K[0-9]+' || awk '/MemTotal/ {printf "%d", int($2/1024)}' /proc/meminfo)
sed -i "s/<<MEMORY>>/${REAL_MEM}/" /etc/slurm/slurm.conf

# Create runtime directories and set permissions
mkdir -p /var/run/munge /var/log/munge
chown munge:munge /var/run/munge /var/log/munge
chmod 755 /var/run/munge
chmod 0700 /var/log/munge

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
