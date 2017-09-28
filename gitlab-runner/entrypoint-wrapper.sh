#!/bin/bash
until gitlab-ci-multi-runner register; do
  sleep 30
done

exec /entrypoint "$@"
