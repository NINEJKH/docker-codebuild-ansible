# based-off alpine-3.10: https://github.com/docker-library/docker/blob/master/19.03/Dockerfile#L1
FROM docker:19-dind

ARG tfenv_version="2.0.0"

VOLUME /var/lib/docker

# Install git, SSH, and other utilities
RUN set -ex && \
    apk add --no-progress --no-cache \
      bash \
      ca-certificates \
      curl \
      curl-dev \
      diffutils \
      g++ \
      gcc \
      git \
      jq \
      libc-dev \
      libffi-dev \
      make \
      ncurses \
      netcat-openbsd \
      openssh \
      openssl-dev \
      pkgconf \
      python3-dev \
      py3-pip \
      ruby-bundler \
      ruby-dev \
      ruby-json \
      sed \
      tree \
      wget \
      zip && \
    mkdir -p ~/.ssh ~/.aws/cli/cache && \
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts && \
    ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts

# pip
RUN pip3 install -U pip
RUN set -ex && \
    pip3 install -U \
      docker-compose \
      awscli \
      boto3 \
      ansible \
      requests \
      cffi

# terraform via tfenv
RUN set -ex && \
    cd /opt && \
    wget "https://github.com/tfutils/tfenv/archive/v${tfenv_version}.tar.gz" && \
    tar xf "v${tfenv_version}.tar.gz" && \
    ln -sf "/opt/tfenv-${tfenv_version}/bin/"* /usr/local/bin && \
    tfenv list-remote | grep 0\.11\. | grep -v '\(alpha\|beta\|rc\|0\.11\.15\)' | head -n5 | xargs -n1 tfenv install && \
    tfenv list-remote | grep 0\.12\. | grep -v '\(alpha\|beta\|rc\)' | head -n5 | xargs -n1 tfenv install && \
    tfenv list-remote | grep 0\.13\. | grep -v '\(alpha\|beta\|rc\)' | head -n10 | xargs -n1 tfenv install

# Configure SSH
COPY ssh_config ~/.ssh/config
COPY dockerd-entrypoint.sh /usr/local/bin/
