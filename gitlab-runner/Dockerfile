FROM gitlab/gitlab-runner

COPY ./entrypoint-wrapper.sh /

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint-wrapper.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
