FROM almalinux:9

LABEL maintainer="Simon Richardson <simon@richardson.nu>"
LABEL description="AlmaLinux 9 Docker image for Ansible testing with Molecule"

ENV container=docker
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_USER=ansible
ENV ANSIBLE_HOME=/home/ansible
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install required packages
RUN dnf -y update && \
    dnf -y install \
        epel-release \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-devel \
        python3-pyyaml \
        sudo \
        which \
        tar \
        unzip \
        rsync \
        procps-ng \
        iproute \
        openssh-clients \
        systemd \
        systemd-devel \
        initscripts \
        util-linux \
        hostname \
        less \
        git \
        vim-minimal \
        && \
    dnf clean all

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install Ansible and related tools
RUN python3 -m pip install \
    ansible \
    molecule \
    molecule-docker \
    ansible-lint \
    yamllint \
    pytest \
    pytest-ansible \
    pytest-molecule \
    jmespath \
    selinux

# Set up systemd
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# Create a non-root user for running Ansible
RUN useradd -m ${ANSIBLE_USER} && \
    echo "${ANSIBLE_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${ANSIBLE_USER} && \
    chmod 0440 /etc/sudoers.d/${ANSIBLE_USER}

# Create Ansible directories with proper permissions
RUN mkdir -p ${ANSIBLE_HOME}/.ansible/tmp && \
    mkdir -p ${ANSIBLE_HOME}/.ansible/cp && \
    mkdir -p ${ANSIBLE_HOME}/.ansible/roles && \
    mkdir -p ${ANSIBLE_HOME}/.ansible/collections && \
    chmod -R 755 ${ANSIBLE_HOME}/.ansible && \
    chown -R ${ANSIBLE_USER}:${ANSIBLE_USER} ${ANSIBLE_HOME}

# Also prepare root's ansible directories
RUN mkdir -p /root/.ansible/tmp && \
    chmod 700 /root/.ansible/tmp

# Set up Ansible configuration
RUN mkdir -p /etc/ansible
COPY ansible.cfg /etc/ansible/ansible.cfg

# Install Ansible inventory file
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts && \
    chown -R ${ANSIBLE_USER}:${ANSIBLE_USER} /etc/ansible/hosts

# Switch to non-root user
USER ${ANSIBLE_USER}
WORKDIR ${ANSIBLE_HOME}

# Configure Ansible environment variables
ENV ANSIBLE_CONFIG=/etc/ansible/ansible.cfg
ENV ANSIBLE_REMOTE_TMP=${ANSIBLE_HOME}/.ansible/tmp
ENV ANSIBLE_LOCAL_TEMP=${ANSIBLE_HOME}/.ansible/tmp
ENV ANSIBLE_REMOTE_USER=${ANSIBLE_USER}
ENV ANSIBLE_PIPELINING=True

# Switch back to root for final steps
USER root
WORKDIR /root

# Clean up
RUN dnf clean all && \
    rm -rf /var/cache/dnf/* && \
    rm -rf /root/.cache && \
    rm -rf ${ANSIBLE_HOME}/.cache

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

# Set the entrypoint to ensure systemd is properly initialized
ENTRYPOINT ["/usr/sbin/init"]
CMD []
