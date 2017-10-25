#!/bin/sh
wait_for_server() {
  until curl --fail --location http://gitlab-ce/api/v4/projects; do
    sleep 30
  done
}

create_session() {
  curl \
    --request POST \
    --form 'login=root' \
    --form "password=${GITLAB_ROOT_PASSWORD}" \
    http://gitlab-ce/api/v4/session
}

create_project() {
  private_token=$1
  name=$2
  import_url=$3

  curl \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Private-Token: ${private_token}" \
    --data "{\"name\": \"${name}\", \"import_url\": \"${import_url}\"}" \
    http://gitlab-ce/api/v4/projects
}

git_origin='https://github.com/andrewshawcare'
project_names=$(cat <<'HEREDOC'
docker-ecosystem-migration
docker-ecosystem-java-service
docker-ecosystem-node-service
docker-ecosystem-client
HEREDOC
)
initial_project='docker-ecosystem-migration'

wait_for_server

private_token="$(create_session | jq --raw-output '.private_token')"

for project_name in ${project_names}; do
  create_project "${private_token}" "${project_name}" "${git_origin}/${project_name}"
done
