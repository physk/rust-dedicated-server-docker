#!/bin/bash

service_name="${DOCKER_SERVICE_NAME:-rust}"
container_user="${DOCKER_CONTAINER_USER:-steam}"

docker compose exec -Tu "$container_user" "$service_name" /utils/get-or-update-plugins.sh
