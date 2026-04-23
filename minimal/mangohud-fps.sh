#!/bin/sh
# Latest FPS from MangoHud CSV logs (enable logging in-game: default Shift+F2).
# Set CONKY_MANGOHUD_LOGDIR to a single folder to search only there.
# Prefers CSVs whose names suggest Ark / UE / Ascended; else newest non-summary .csv.

set -eu

pick_csv() {
  if [ -n "${CONKY_MANGOHUD_LOGDIR:-}" ] && [ -d "${CONKY_MANGOHUD_LOGDIR}" ]; then
    dirs="${CONKY_MANGOHUD_LOGDIR}"
  else
    dirs="${HOME}/.config/MangoHud/mangologs ${HOME}/.local/share/MangoHud"
  fi
  f=""
  for d in $dirs; do
    [ -d "$d" ] || continue
    f="$(
      find "$d" -maxdepth 3 -type f \( \
        -iname '*ark*.csv' -o -iname '*ascended*.csv' -o -iname '*shooter*.csv' -o -iname '*survival*.csv' \
      \) ! -iname '*_summary.csv' -printf '%T@\t%p\n' 2>/dev/null | sort -n | tail -1 | cut -f2-
    )"
    [ -n "$f" ] && break
  done
  if [ -z "$f" ]; then
    for d in $dirs; do
      [ -d "$d" ] || continue
      f="$(
        find "$d" -maxdepth 3 -type f -iname '*.csv' ! -iname '*_summary.csv' \
          -printf '%T@\t%p\n' 2>/dev/null | sort -n | tail -1 | cut -f2-
      )"
      [ -n "$f" ] && break
    done
  fi
  printf '%s' "$f"
}

csv="$(pick_csv)"
[ -z "$csv" ] || [ ! -r "$csv" ] && printf '%s\n' '—' && exit 0

awk '
  BEGIN { in_data = 0; fps = "" }
  {
    sub(/\r$/, "")
    if ($1 == "fps" || index($0, "fps,") == 1) { in_data = 1; next }
    if (in_data && NF >= 1 && $1 ~ /^-?[0-9]+\.?[0-9]*$/) { fps = $1 }
  }
  END {
    if (fps != "") printf "%.0f\n", fps + 0
    else print "—"
  }
' "$csv"
