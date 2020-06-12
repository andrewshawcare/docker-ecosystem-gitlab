#!/bin/sh
wait_for_server() {
  sleep 180
  until [ "$(curl --silent --output /dev/null --write-out '%{http_code}' http://gitlab-ce/api/v4/session)" -eq 404 ]; do
    sleep 30
  done
}

create_oauth_token() {
  curl \
    --request POST \
    --header 'Content-Type: application/json' \
    --data "{\"grant_type\": \"password\", \"username\": \"root\", \"password\": \"${GITLAB_ROOT_PASSWORD}\"}" \
    http://gitlab-ce/oauth/token
}

create_project() {
  access_token=$1
  name=$2
  import_url=$3

  curl \
    --retry 5 \
    --retry-delay 0 \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${access_token}" \
    --data "{\"name\": \"${name}\", \"import_url\": \"${import_url}\"}" \
    http://gitlab-ce/api/v4/projects
}

create_project_pipeline_trigger() {
  access_token=$1
  project_id=$2
  description=$3

  curl \
    --retry 5 \
    --retry-delay 0 \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${access_token}" \
    --data "{\"id\": \"${project_id}\", \"description\": \"${description}\"}" \
    "http://gitlab-ce/api/v4/projects/${project_id}/triggers"
}

trigger_project_pipeline() {
  access_token=$1
  project_id=$2
  trigger_token=$3
  ref=$4

  curl \
    --retry 5 \
    --retry-delay 0 \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${access_token}" \
    --data "{\"token\": \"${trigger_token}\", \"ref\": \"${ref}\"}" \
    "http://gitlab-ce/api/v4/projects/${project_id}/trigger/pipeline"
}

downstream_project_names() {
  project_name=$1
  case $project_name in
    'docker-ecosystem-migration' ) echo 'docker-ecosystem-java-service docker-ecosystem-node-service' ;;
    'docker-ecosystem-java-service' ) echo 'docker-ecosystem-client' ;;
    'docker-ecosystem-node-service' ) echo 'docker-ecosystem-client' ;;
    'docker-ecosystem-client' ) echo '' ;;
  esac
}

create_project_level_variable() {
  access_token=$1
  project_id=$2
  key=$3
  value=$4

  curl \
    --retry 5 \
    --retry-delay 0 \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${access_token}" \
    --data "{\"key\": \"${key}\", \"value\": \"${value}\"}" \
    "http://gitlab-ce/api/v4/projects/${project_id}/variables"
}

wait_for_server

access_token="$(create_oauth_token | jq --raw-output '.access_token')"

namespace='root'
project_names=$(cat <<'HEREDOC'
docker-ecosystem-migration
docker-ecosystem-java-service
docker-ecosystem-node-service
docker-ecosystem-client
HEREDOC
)
git_origin='https://github.com/andrewshawcare'

# Create projects
for project_name in ${project_names}; do
  create_project "${access_token}" "${project_name}" "${git_origin}/${project_name}"
done

# Create downstream project triggers and add them as project-level variables
for project_name in ${project_names}; do
  for downstream_project_name in $(downstream_project_names $project_name); do
    project_id="${namespace}%2f${project_name}"
    downstream_project_id="${namespace}%2f${downstream_project_name}"
    trigger_token="$(create_project_pipeline_trigger ${access_token} ${downstream_project_id} ${project_name} | jq --raw-output '.token')"
    key="$(echo "${downstream_project_name}_TRIGGER_TOKEN" | tr '-' '_' | tr '[:lower:]' '[:upper:]')"
    create_project_level_variable ${access_token} ${project_id} ${key} ${trigger_token}
  done
done

# Trigger initial pipeline
initial_project_name='docker-ecosystem-migration'
initial_project_id="${namespace}%2f${initial_project_name}"
initial_trigger="$(create_project_pipeline_trigger ${access_token} ${initial_project_id} 'Initial project trigger')"
initial_trigger_token="$(echo ${initial_trigger} | jq --raw-output '.token')"

trigger_project_pipeline ${access_token} ${initial_project_id} ${initial_trigger_token} 'master'
