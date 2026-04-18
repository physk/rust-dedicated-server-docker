#!/bin/bash

service_name="${DOCKER_SERVICE_NAME:-rust}"
docker compose exec -T "$service_name" /bin/bash -ec 'unix2dos serverfiles/oxide/plugins/*.cs'
