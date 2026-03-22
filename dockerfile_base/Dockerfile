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


## BUILD IMAGE: ROOT USER ----------------------------------------------------
FROM rockylinux:${ROCKY_VERSION} AS stage-root
ARG TIMEZONE
ARG ROCKY_VERSION
ARG SLURM_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add Slurm RPM repository
RUN ROCKY_MAJOR=$(echo ${ROCKY_VERSION} | cut -d. -f1) \
    && printf "[slurm]\nname=Slurm RPM Repository\nbaseurl=https://omnivector-solutions.github.io/slurm-repo/${SLURM_VERSION}/rocky${ROCKY_MAJOR}/x86_64\nenabled=1\ngpgcheck=0\n" \
       > /etc/yum.repos.d/slurm.repo

# Install EPEL, enable CRB/PowerTools (needed for dependencies on EL8),
# and run system updates
# hadolint ignore=DL3041
RUN dnf -y install epel-release \
    && (dnf config-manager --set-enabled crb 2>/dev/null \
        || dnf config-manager --set-enabled powertools 2>/dev/null \
        || true) \
    && dnf -y upgrade \
    && dnf clean all

# Set time zone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo ${TIMEZONE} > /etc/timezone

# Set locale
# hadolint ignore=DL3041
RUN dnf -y install glibc-langpack-en \
    && dnf clean all
ENV LANG=en_US.UTF-8

# Create slurm user/group (RPMs may not create them)
RUN groupadd -r slurm 2>/dev/null || true \
    && useradd -r -g slurm -d /nonexistent -s /sbin/nologin slurm 2>/dev/null || true

# Install munge and Slurm
# hadolint ignore=DL3041
RUN dnf -y install munge munge-libs \
                   slurm slurm-slurmd slurm-slurmctld \
    && dnf clean all

# Generate munge key and fix log directory ownership
RUN dd if=/dev/urandom of=/etc/munge/munge.key bs=1 count=1024 2>/dev/null \
    && chown munge:munge /etc/munge/munge.key /var/log/munge \
    && chmod 400 /etc/munge/munge.key

# Slurm configuration
RUN mkdir -p /etc/slurm
COPY slurm.conf /etc/slurm/slurm.conf
RUN mkdir -p /var/spool/slurmctld /var/spool/slurmd \
    && chown slurm:slurm /var/spool/slurmctld

# Startup configuration
COPY startup.sh /etc/startup.sh
RUN chmod 555 /etc/startup.sh

# Set working directory and default command when running container
WORKDIR /root
# hadolint ignore=DL3025
CMD /etc/startup.sh ; /bin/bash -l


## BUILD IMAGE: STANDARD USER ------------------------------------------------
FROM stage-root AS stage-standard
ARG USERNAME
ARG PASSWORD
ARG UID

# Create user account and add to "wheel" group
# hadolint ignore=DL3041
RUN dnf -y install sudo openssl \
    && dnf clean all
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
# hadolint ignore=DL3025
CMD sudo /etc/startup.sh ; /bin/bash -l


# SELECT DESIRED USER PRIVILEGE LEVEL ----------------------------------------
# hadolint ignore=DL3006
FROM stage-${USER_PRIVILEGE_LEVEL}
