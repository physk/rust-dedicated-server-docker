#!/bin/bash
# DESCRIPTION:
#   Standalone Rust bootstrap/start script without LinuxGSM runtime control.
#   First boot flow:
#     1) ensure steamcmd is present
#     2) install/update RustDedicated via steamcmd
#     3) generate server.cfg from env vars
#     4) optionally install Oxide/uMod and plugins
#     5) start RustDedicated

set -euo pipefail

cd /home/steam

log() {
  printf '%s\n' "$*"
}

ensure_steamcmd() {
  if [ -x "${STEAMCMD_PATH:-}" ]; then
    STEAMCMD_BIN="$STEAMCMD_PATH"
    return
  fi

  if command -v steamcmd >/dev/null 2>&1; then
    STEAMCMD_BIN="$(command -v steamcmd)"
    return
  fi

  local local_steamcmd="$HOME/steamcmd/steamcmd.sh"
  if [ -x "$local_steamcmd" ]; then
    STEAMCMD_BIN="$local_steamcmd"
    return
  fi

  log 'steamcmd not found. Downloading local steamcmd...'
  mkdir -p "$HOME/steamcmd"
  curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | \
    tar -xz -C "$HOME/steamcmd"
  STEAMCMD_BIN="$local_steamcmd"
}

install_or_update_rust() {
  local rust_binary="$HOME/serverfiles/RustDedicated"
  local mode="${RUST_UPDATE_MODE:-if-missing}"

  if [ ! -x "$rust_binary" ] || [ "$mode" = "always" ]; then
    log 'Installing/updating RustDedicated with steamcmd...'
    "$STEAMCMD_BIN" \
      +force_install_dir "$HOME/serverfiles" \
      +login anonymous \
      +app_update 258550 validate \
      +quit
  else
    log 'RustDedicated exists; skipping update (RUST_UPDATE_MODE=if-missing).'
  fi
}

ensure_rcon_password() {
  if [ ! -f "$HOME/rcon_pass" ]; then
    tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12 > "$HOME/rcon_pass"
    echo >> "$HOME/rcon_pass"
  fi
}

install_oxide_if_enabled() {
  if [ "${ENABLE_OXIDE:-false}" != "true" ]; then
    log 'Oxide disabled (ENABLE_OXIDE!=true).'
    return
  fi

  if [ -f "$HOME/serverfiles/RustDedicated_Data/Managed/Oxide.Core.dll" ]; then
    log 'Oxide already present; skipping install.'
    return
  fi

  local oxide_url="${OXIDE_DOWNLOAD_URL:-https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip}"
  local zip_file="$HOME/Oxide.Rust-linux.zip"
  log "Installing Oxide from: $oxide_url"
  curl -fLso "$zip_file" "$oxide_url"
  unzip -o "$zip_file" -d "$HOME/serverfiles"
  rm -f "$zip_file"
}

install_mods_if_enabled() {
  if [ "${ENABLE_OXIDE:-false}" = "true" ]; then
    /utils/get-or-update-plugins.sh
  fi
}

start_custom_map_server_if_needed() {
  if [ "${SELF_HOST_CUSTOM_MAP:-false}" != "true" ]; then
    return
  fi
  if ! ls /custom-maps/*.map >/dev/null 2>&1; then
    return
  fi
  (
    cd /custom-maps
    python3 -m http.server 8000 >/tmp/custom-map-http.log 2>&1 &
  )
  sleep 1
}

build_rust_command() {
  local host_name="${servername:-Rust}"
  local identity="${RUST_SERVER_IDENTITY:-rustserver}"
  local ip="${RUST_SERVER_IP:-0.0.0.0}"
  local port="${RUST_SERVER_PORT:-28015}"
  local rcon_port="${RUST_RCON_PORT:-28016}"
  local max_players="${maxplayers:-50}"
  local save_interval="${RUST_SAVE_INTERVAL:-300}"
  local seed_value="${seed:-1337}"
  local salt_value="${salt:-12345}"
  local world_size="${worldsize:-3000}"
  local rcon_password
  rcon_password="$(< "$HOME/rcon_pass")"

  cmd=(
    "$HOME/serverfiles/RustDedicated"
    -batchmode
    +server.ip "$ip"
    +server.port "$port"
    +server.identity "$identity"
    +server.hostname "$host_name"
    +server.maxplayers "$max_players"
    +server.saveinterval "$save_interval"
    +rcon.web 1
    +rcon.ip "$ip"
    +rcon.port "$rcon_port"
    +rcon.password "$rcon_password"
  )

  if [ -n "${CUSTOM_MAP_URL:-}" ]; then
    cmd+=( +levelurl "$CUSTOM_MAP_URL" )
  elif [ "${SELF_HOST_CUSTOM_MAP:-false}" = "true" ] && ls /custom-maps/*.map >/dev/null 2>&1; then
    local first_map
    first_map="$(find /custom-maps -maxdepth 1 -type f -name '*.map' | head -n1)"
    cmd+=( +levelurl "${MAP_BASE_URL:-http://localhost:8000}/$(basename "$first_map")" )
  else
    cmd+=( +server.seed "$seed_value" +server.salt "$salt_value" +server.worldsize "$world_size" )
  fi

  cmd+=( -logfile "$HOME/log/console/rustserver-console.log" )
}

main() {
  mkdir -p "$HOME/serverfiles/server/rustserver/cfg" "$HOME/log/console"
  ensure_steamcmd
  install_or_update_rust

  CFG_FILE="$HOME/serverfiles/server/rustserver/cfg/server.cfg" /utils/gen-cfg.sh
  ensure_rcon_password
  install_oxide_if_enabled
  install_mods_if_enabled
  start_custom_map_server_if_needed

  build_rust_command
  log 'Starting RustDedicated (steamcmd bootstrap mode)...'
  exec "${cmd[@]}"
}

main "$@"
