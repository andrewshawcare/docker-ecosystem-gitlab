#!/bin/bash
# Ensure the volume-mounted docker socket is accessible to users in the docker group
chgrp docker /var/run/docker.sock

until gitlab-ci-multi-runner register; do
  sleep 30
done

exec /entrypoint "$@"
