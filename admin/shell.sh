#!/bin/bash

service_name="${DOCKER_SERVICE_NAME:-rust}"
container_user="${DOCKER_CONTAINER_USER:-steam}"

docker exec -itu "${1:-$container_user}" "$(docker compose ps -q "$service_name")" /bin/bash
