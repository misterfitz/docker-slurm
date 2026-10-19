## SETTINGS ------------------------------------------------------------------
ARG USER_PRIVILEGE_LEVEL
ARG ROCKY_VERSION=9

# Settings for all images
ARG TIMEZONE
ARG SLURM_VERSION

# Settings for standard user images
ARG USERNAME
ARG PASSWORD
ARG UID


## BUILD SLURM RPMS ----------------------------------------------------------
FROM rockylinux/rockylinux:${ROCKY_VERSION} AS rpm-builder
ARG SLURM_VERSION

# Install RPM build tools and enable EPEL/CRB (CRB provides munge-devel)
RUN dnf -y install epel-release dnf-plugins-core rpm-build tar bzip2 \
    && dnf config-manager --set-enabled crb

# Build Slurm RPMs from the official SchedMD source tarball, installing the
# build dependencies declared in that version's spec file
WORKDIR /build
RUN curl -fsSLO https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 \
    && tar -xjf slurm-${SLURM_VERSION}.tar.bz2 slurm-${SLURM_VERSION}/slurm.spec \
    && dnf -y builddep slurm-${SLURM_VERSION}/slurm.spec \
    && rpmbuild -ta slurm-${SLURM_VERSION}.tar.bz2 \
    && rm -f /root/rpmbuild/RPMS/x86_64/*-debug*.rpm


## BUILD IMAGE: ROOT USER ----------------------------------------------------
FROM rockylinux/rockylinux:${ROCKY_VERSION} AS stage-root
ARG TIMEZONE
ARG SLURM_VERSION

# Install EPEL, enable CRB, and run system updates (openssl is not included
# in the Rocky 10 container image)
RUN dnf -y install epel-release dnf-plugins-core openssl \
    && dnf config-manager --set-enabled crb \
    && dnf -y upgrade

# Add a local repository with the Slurm RPMs (also used by the full image to
# install slurm-devel and slurm-contribs). priority=1 keeps dnf from replacing
# them with the slurm packages EPEL ships.
COPY --from=rpm-builder /root/rpmbuild/RPMS/x86_64/ /opt/slurm-rpms/
RUN dnf -y install createrepo_c \
    && createrepo_c /opt/slurm-rpms \
    && printf "[slurm]\nname=Slurm ${SLURM_VERSION} (built from SchedMD source)\nbaseurl=file:///opt/slurm-rpms\nenabled=1\ngpgcheck=0\npriority=1\n" \
       > /etc/yum.repos.d/slurm.repo

# Set time zone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo ${TIMEZONE} > /etc/timezone

# Set locale
RUN dnf -y install glibc-langpack-en
ENV LANG=en_US.UTF-8

# Install munge and Slurm, and verify the expected Slurm version was installed
RUN dnf -y install munge munge-libs \
                   slurm slurm-slurmd slurm-slurmctld \
    && [ "$(rpm -q --qf '%{VERSION}' slurm)" = "${SLURM_VERSION}" ]

# Create slurm user/group (the SchedMD RPMs do not include user-creation
# scriptlets)
RUN getent group slurm >/dev/null || groupadd -r slurm \
    && getent passwd slurm >/dev/null || useradd -r -g slurm -d /nonexistent -s /sbin/nologin slurm

# Generate munge key and fix log directory ownership
RUN dd if=/dev/urandom of=/etc/munge/munge.key bs=1 count=1024 2>/dev/null \
    && chown munge:munge /etc/munge/munge.key /var/log/munge \
    && chmod 400 /etc/munge/munge.key \
    && chmod 0700 /var/log/munge

# Slurm configuration
RUN mkdir -p /etc/slurm
COPY slurm.conf /etc/slurm/slurm.conf

# Slurm 24.05+ defaults to cgroup/v2 which requires dbus (unavailable in
# containers). Write cgroup.conf to force cgroup/v1 for versions >= 24.
RUN SLURM_MAJOR=$(echo ${SLURM_VERSION} | cut -d. -f1) \
    && if [ "$SLURM_MAJOR" -ge 24 ]; then \
         echo "CgroupPlugin=cgroup/v1" > /etc/slurm/cgroup.conf; \
       fi

RUN mkdir -p /var/spool/slurmctld /var/spool/slurmd \
    && chown slurm:slurm /var/spool/slurmctld

# Startup configuration
COPY startup.sh /etc/startup.sh
RUN chmod 555 /etc/startup.sh

# Set working directory and default command when running container
WORKDIR /root
CMD /etc/startup.sh ; /bin/bash -l


## BUILD IMAGE: STANDARD USER ------------------------------------------------
FROM stage-root AS stage-standard
ARG USERNAME
ARG PASSWORD
ARG UID

# Create user account and add to "wheel" group
RUN dnf -y install sudo openssl
RUN useradd --create-home --uid=${UID} ${USERNAME} -p "$(openssl passwd -1 ${PASSWORD})" \
    && usermod -a -G wheel ${USERNAME}

# Configure user permissions for startup script
RUN printf "${USERNAME} ALL=(root:root) NOPASSWD: /etc/startup.sh\n" >> /etc/sudoers.d/startup \
    && chmod 0440 /etc/sudoers.d/startup \
    && visudo -c

# Set standard user as default
USER ${USERNAME}

# Enable colored Bash terminal prompt
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc

# Set working directory and default command when running container
WORKDIR /home/${USERNAME}
CMD sudo /etc/startup.sh ; /bin/bash -l


# SELECT DESIRED USER PRIVILEGE LEVEL ----------------------------------------
FROM stage-${USER_PRIVILEGE_LEVEL}
