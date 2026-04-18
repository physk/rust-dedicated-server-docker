#!/bin/bash
# DESCRIPTION:
#   Container entrypoint. Runs as root.
#   Handles PUID/PGID remapping, volume ownership, then launches
#   custom-rust-server.sh as the linuxgsm user.

set -ex

# Belt-and-suspenders: remove sudoers entry on any exit path
trap 'rm -f /etc/sudoers.d/lgsm' EXIT

# Grant temporary passwordless sudo for initial LGSM setup.
# Removed by custom-rust-server.sh once setup completes.
echo 'linuxgsm  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/lgsm

# Remap linuxgsm UID/GID to match the host user (linuxserver-style PUID/PGID).
# Defaults to 1000/1000. Set PUID and PGID in .env to match your host user.
PUID=${PUID:-1000}
PGID=${PGID:-1000}
if [ ! "$(id -u linuxgsm)" = "$PUID" ]; then
    usermod -o -u "$PUID" linuxgsm
fi
if [ ! "$(id -g linuxgsm)" = "$PGID" ]; then
    groupmod -o -g "$PGID" linuxgsm
fi

# Fix ownership on volume-mounted paths
[ "$(stat -c '%u' /home/linuxgsm)" != "$PUID" ] && chown -R linuxgsm: /home/linuxgsm
[ "$(stat -c '%u' /custom-maps)" != "$PUID" ] && chown -R linuxgsm: /custom-maps
for dir in /home/linuxgsm/serverfiles /home/linuxgsm/serverfiles/oxide; do
    [ -d "$dir" ] && chown linuxgsm: "$dir"
done
[ -d /home/linuxgsm/serverfiles/oxide/config ] && \
    chown -R linuxgsm: /home/linuxgsm/serverfiles/oxide/config

rm -f ~linuxgsm/linuxgsm.sh

# su - creates a clean login shell that drops environment variables.
# Write server config vars to /etc/profile.d so they are sourced
# automatically by the login shell and all child processes.
{
  for var in maxplayers servername seed salt worldsize \
              ENABLE_RUST_EAC MAP_BASE_URL CUSTOM_MAP_URL \
              SELF_HOST_CUSTOM_MAP uptime_monitoring \
              apply_settings_debug_mode LINUX_GSM_VERSION PLUGIN_LIST; do
    if [ -n "${!var+x}" ]; then
      printf 'export %s=%q\n' "$var" "${!var}"
    fi
  done
} > /etc/profile.d/lgsm-runtime-env.sh

exec su - linuxgsm -c "/utils/custom-rust-server.sh"
