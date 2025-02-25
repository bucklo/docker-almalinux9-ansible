FROM almalinux:9
LABEL maintainer="Simon Richardson"
ENV container=docker

RUN dnf -y update \
  && yum -y install \
    python3 \
    python3-pip \
    python3-pyyaml \
  && dnf clean all

# Upgrade pip to latest version.
RUN pip3 install --upgrade pip

# Install Ansible via Pip.
RUN pip3 install ansible

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts
