#!/bin/sh
# Up/down for selected Docker containers (name substring match: jellyfin, emby, comfyui).
set -eu
svc="${1:-}"
if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' '?'
  exit 0
fi
case "$svc" in
  jellyfin) filter=jellyfin ;;
  emby) filter=emby ;;
  comfyui) filter=comfyui ;;
  *) printf '%s\n' '?'; exit 0 ;;
esac
if docker ps -q --filter "name=${filter}" 2>/dev/null | head -1 | grep -q .; then
  printf '%s\n' up
else
  printf '%s\n' down
fi
