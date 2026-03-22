## SETTINGS ------------------------------------------------------------------
ARG USER_PRIVILEGE_LEVEL

# Settings for all images
ARG BASE_DOCKER_REPO
ARG BASE_TAG

# Settings for standard user images
ARG USERNAME
ARG PASSWORD
ARG UID


## BUILD IMAGE: ROOT USER ----------------------------------------------------
FROM ${BASE_DOCKER_REPO}:${BASE_TAG} AS stage-root

# Run system updates
RUN dnf -y upgrade

# Install system packages
RUN dnf -y install bc \
                   gcc gcc-c++ make \
                   curl \
                   dos2unix \
                   gdb \
                   git \
                   graphviz \
                   htop \
                   lshw \
                   nano \
                   net-tools \
                   openssl \
                   python3-pip \
                   python3-tkinter \
                   slurm-devel \
                   slurm-contribs \
                   tree \
                   vim \
                   wget \
                   zip

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

# Add Python package executables to PATH
ENV PATH="${PATH}:/home/${USERNAME}/.local/bin"

# Set working directory and default command when running container
WORKDIR /home/${USERNAME}
CMD sudo /etc/startup.sh ; /bin/bash -l


# SELECT DESIRED USER PRIVILEGE LEVEL ----------------------------------------
FROM stage-${USER_PRIVILEGE_LEVEL}
