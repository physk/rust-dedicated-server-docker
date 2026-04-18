#!/bin/bash

service_name="${DOCKER_SERVICE_NAME:-rust}"

echo -n 'RCON password: '
docker compose exec -T "$service_name" cat rcon_pass 2> /dev/null || (
  # Could not find rcon random password file so falling back to auto detection.
  docker compose exec -T "$service_name" pgrep RustDedicated | \
  xargs -n1 -I'{}' -- docker compose exec -T "$service_name" cat '/proc/{}/cmdline' | \
  tr '\0' '\n' | \
  awk '$1 == "+rcon.password" { x="1"; next}; x == "1" {print $0; exit}'
)

echo '
Visit one of the following web RCON clients:

- http://facepunch.github.io/webrcon address 127.0.0.1:28016
- http://rcon.io/login address 127.0.0.1 port 28016
'
