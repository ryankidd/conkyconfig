#!/bin/sh
# nvidia-smi fallback when Conky's ${nvidia} (XNVCtrl) is unavailable (e.g. Wayland).
case "${1:-}" in
  metrics)
    nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk -F', ' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); gsub(/^[ \t]+|[ \t]+$/,"",$2); print $1 "°  " $2 "%"}'
    ;;
  gputemp)
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk '{gsub(/^[ \t]+|[ \t]+$/,"",$1); if ($1!="") print $1 "°C"; else print "-"}'
    ;;
  gputempconky)
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk '{
        gsub(/^[ \t]+|[ \t]+$/,"",$1)
        t = $1 + 0
        if (t <= 0) { print "${color cccccc}-${color ffffff}"; exit }
        if (t>=90) c="ff4444"
        else if (t>=80) c="ff9900"
        else if (t>=70) c="ffcc00"
        else if (t>=60) c="ffffaa"
        else c="ffffff"
        printf "${color %s}%.0f°C${color ffffff}\n", c, t
      }'
    ;;
  gpuutil)
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 |
      awk '{gsub(/^[ \t]+|[ \t]+$/,"",$1); if ($1!="") print $1 "%"; else print "-"}'
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
