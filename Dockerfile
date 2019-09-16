# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

FROM debian:10-slim

ENV DEBIAN_FRONTEND="noninteractive" \
    DOCKER_BUCKET="download.docker.com" \
    DOCKER_VERSION="19.03.2" \
    DOCKER_CHANNEL="stable" \
    DOCKER_SHA256="865038730c79ab48dfed1365ee7627606405c037f46c9ae17c5ec1f487da1375" \
    DIND_COMMIT="37498f009d8bf25fbb6199e8ccd34bed84f2874b" \
    TFENV_VERSION="1.0.1"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get -qq update \
    && apt-get -y -qq install apt-transport-https \
    && apt-get -y -qq install \
        bash \
        curl \
        wget \
        ca-certificates \
        git \
        openssh-client \
        python3-dev \
        libssl-dev \
        make \
        autoconf \
        automake \
        gcc \
        g++ \
        libffi-dev \
        unzip \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && chmod +x /usr/local/bin/dind

# Install dependencies by all python images equivalent to buildpack-deps:jessie
# on the public repos.

RUN set -ex \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && pip3 install \
        docker-compose \
        awscli \
        boto3 \
        ansible \
        requests \
        cffi

RUN set -ex \
    && cd /opt \
    && wget "https://github.com/tfutils/tfenv/archive/v${TFENV_VERSION}.tar.gz" \
    && tar xf "v${TFENV_VERSION}.tar.gz" \
    && ln -sf "/opt/tfenv-${TFENV_VERSION}/bin/"* /usr/local/bin \
    && tfenv install "$(tfenv list-remote | grep -v 0\.11\.15 | grep 0\.11\. | head -n1)" \
    && tfenv install "$(tfenv list-remote | grep 0\.12\. | head -n1)"

VOLUME /var/lib/docker

# Configure SSH
COPY ssh_config /root/.ssh/config

COPY dockerd-entrypoint.sh /usr/local/bin/

CMD ["python3"]
