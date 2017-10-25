FROM gitlab/gitlab-runner

ARG DEBIAN_FRONTEND=noninteractive

COPY ./install-docker-compose.sh .
COPY ./install-docker.sh .

RUN apt-get update -y && \
  ./install-docker.sh && \
  ./install-docker-compose.sh && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN usermod -aG docker gitlab-runner

COPY ./entrypoint-wrapper.sh /

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint-wrapper.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
