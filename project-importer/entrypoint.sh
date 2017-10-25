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

search_for_projects_by_name() {
  private_token=$1
  search=$2

  curl \
    --request GET \
    --get \
    --header "Private-Token: ${private_token}" \
    --data "search=${search}" \
    http://gitlab-ce/api/v4/projects
}

create_project_pipeline_trigger() {
  private_token=$1
  project_id=$2
  description=$3

  curl \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Private-Token: ${private_token}" \
    --data "{\"id\": \"${project_id}\", \"description\": \"${description}\"}" \
    "http://gitlab-ce/api/v4/projects/${project_id}/triggers"
}

trigger_project_pipeline() {
  private_token=$1
  project_id=$2
  trigger_token=$3
  ref=$4

  curl \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "Private-Token: ${private_token}" \
    --data "{\"token\": \"${trigger_token}\", \"ref\": \"${ref}\"}" \
    "http://gitlab-ce/api/v4/projects/${project_id}/trigger/pipeline"
}

wait_for_server

project_names=$(cat <<'HEREDOC'
docker-ecosystem-migration
docker-ecosystem-java-service
docker-ecosystem-node-service
docker-ecosystem-client
HEREDOC
)
private_token="$(create_session | jq --raw-output '.private_token')"
git_origin='https://github.com/andrewshawcare'

for project_name in ${project_names}; do
  create_project "${private_token}" "${project_name}" "${git_origin}/${project_name}"
done

initial_project_id="$(search_for_projects_by_name "${private_token}" 'docker-ecosystem-migration' | jq --raw-output '.[0].id')"

trigger="$(create_project_pipeline_trigger ${private_token} ${initial_project_id} 'Initial project trigger')"
trigger_token="$(echo ${trigger} | jq --raw-output '.token')"

trigger_project_pipeline ${private_token} ${initial_project_id} ${trigger_token} 'master'
