#!/bin/sh
# CPU °C from hwmon sysfs (k10temp / zenpower / coretemp). Works when `sensors` prints nothing.
# Plain: ./cpu-temp.sh  →  66.0°C
# Conky: ./cpu-temp.sh conky  →  ${color ...}66.0°C${color ffffff}  (use ${execpi ...} in conky.text)
t=""
for d in /sys/class/hwmon/hwmon*/; do
  chip=$(cat "${d}name" 2>/dev/null) || continue
  case "$chip" in
    k10temp|zenpower|coretemp) ;;
    *) continue ;;
  esac
  f="${d}temp1_input"
  if [ -r "$f" ]; then
    read -r raw < "$f" || continue
    t=$(awk -v r="$raw" 'BEGIN{ if (r+0 > 0) print r/1000; else print "" }')
    break
  fi
done

case "$1" in
  conky)
    if [ -z "$t" ]; then
      echo '${color cccccc}-${color ffffff}'
      exit 0
    fi
    awk -v t="$t" 'BEGIN{
      if (t>=90) c="ff4444"
      else if (t>=80) c="ff9900"
      else if (t>=70) c="ffcc00"
      else if (t>=60) c="ffffaa"
      else c="ffffff"
      printf "${color %s}%.1f°C${color ffffff}\n", c, t
    }'
    ;;
  *)
    if [ -z "$t" ]; then
      echo "-"
    else
      awk -v t="$t" 'BEGIN{ printf "%.1f°C\n", t }'
    fi
    ;;
esac
