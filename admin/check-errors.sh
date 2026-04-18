#!/bin/bash

# DESCRIPTION:
#   Quick validation helper for this repository.
#   - Validates shell script syntax
#   - Optionally validates docker compose if docker is available
#   - Surfaces LinuxGSM coupling locations for refactor planning

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

pass() {
  printf 'OK: %s\n' "$*"
}

shell_targets=(
  utils/*.sh
  admin/*.sh
  admin/backup/*.sh
  admin/logs/*.sh
)

pass "Running shell syntax checks"
for f in "${shell_targets[@]}"; do
  bash -n "$f"
done
pass "All shell scripts parsed successfully"

if command -v docker >/dev/null 2>&1; then
  pass "Validating docker compose"
  docker compose config -q
  pass "docker compose config is valid"
else
  warn "docker command not found; skipped 'docker compose config -q'"
fi

legacy_hits="$(rg -n "\\blgsm\\b|linuxgsm" README.md docker-compose.yml Dockerfile utils admin | wc -l)"
if [ "$legacy_hits" -gt 0 ]; then
  warn "Detected ${legacy_hits} legacy LinuxGSM references."
fi

pass "Checks completed"
