#!/bin/sh
# nvidia-smi fallback when Conky's ${nvidia} (XNVCtrl) is unavailable (e.g. Wayland).
case "${1:-}" in
  metrics)
    nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk -F', ' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); gsub(/^[ \t]+|[ \t]+$/,"",$2); print $1 "°  " $2 "%"}'
    ;;
  model)
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1
    ;;
  vram)
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk -F', ' '{
        gsub(/^[ \t]+|[ \t]+$/,"",$1)
        gsub(/^[ \t]+|[ \t]+$/,"",$2)
        u = $1 * 1048576 / 1e9
        t = $2 * 1048576 / 1e9
        printf "%.0f/%.0fGb\n", u, t
      }'
    ;;
  memutil)
    nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -cd '0-9'
    ;;
  graph)
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -cd '0-9'
    ;;
esac
