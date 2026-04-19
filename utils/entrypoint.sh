#!/bin/bash
# DESCRIPTION:
#   Container entrypoint for standalone SteamCMD/RustDedicated flow.

set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

if [ "$(id -u steam)" != "$PUID" ]; then
  usermod -o -u "$PUID" steam
fi
if [ "$(id -g steam)" != "$PGID" ]; then
  groupmod -o -g "$PGID" steam
fi

mkdir -p /home/steam /custom-maps

bash /utils/gen-cfg.sh
chown -R steam:steam /home/steam /custom-maps
exec gosu steam bash /utils/custom-rust-server.sh
