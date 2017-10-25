#!/bin/bash
apt-get install -y curl jq

VERSION="$(curl https://api.github.com/repos/docker/compose/releases/latest | jq --raw-output .name)"
KERNEL="$(uname -s)"
MACHINE="$(uname -m)"

curl \
  --location \
  --output /usr/local/bin/docker-compose \
  "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-${KERNEL}-${MACHINE}" \

chmod +x /usr/local/bin/docker-compose
