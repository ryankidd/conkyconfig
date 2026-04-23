#!/bin/sh
# Decimal gigabytes (SI, 1e9), suffix "Gb", format used/totalGb — mem, swap, fs.
set -eu
case "${1:-}" in
  mem)
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2}
      END {
        if (t + 0 == 0) { print "0/0Gb"; exit }
        u = (t - a) * 1024 / 1e9
        tot = t * 1024 / 1e9
        printf "%.0f/%.0f GB\n", u, tot
      }' /proc/meminfo
    ;;
  swap)
    awk '/^SwapTotal:/{t=$2} /^SwapFree:/{f=$2}
      END {
        if (t + 0 == 0) { print "0/0Gb"; exit }
        u = (t - f) * 1024 / 1e9
        tot = t * 1024 / 1e9
        printf "%.0f/%.0f GB\n", u, tot
      }' /proc/meminfo
    ;;
  fs)
    mp="${2:-/}"
    df --si -BG "$mp" 2>/dev/null | awk 'NR==2 {
      gsub(/G$/,"", $3)
      gsub(/G$/,"", $2)
      printf "%s/%s GB\n", $3, $2
    }'
    ;;
esac
