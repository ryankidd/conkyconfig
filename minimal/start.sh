#!/bin/bash
set -euo pipefail

CFG="${HOME}/.conky/minimal/conky.conf"

if [[ -n "${XDG_RUNTIME_DIR:-}" ]] && systemctl --user -q is-system-running 2>/dev/null; then
  systemctl --user restart conky-minimal.service
  exit 0
fi

pkill -f "conky.*minimal/conky\\.conf" 2>/dev/null || true
sleep 1
/usr/bin/conky -c "$CFG" &
