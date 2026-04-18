#!/usr/bin/env bash
set -euo pipefail

CFG_FILE="${CFG_FILE:-/home/steam/serverfiles/server/rustserver/cfg/server.cfg}"
MAP_FILE="${MAP_FILE:-/app/server/convars.map}"

mkdir -p "$(dirname "$CFG_FILE")"
: > "$CFG_FILE"

while IFS='|' read -r key env_name default; do
  [[ -z "${key}" ]] && continue
  [[ "${key:0:1}" == "#" ]] && continue

  value="${!env_name:-$default}"
  printf '%s %s\n' "$key" "$value" >> "$CFG_FILE"
done < "$MAP_FILE"
