#!/bin/sh
# One line of host vitals for herdr's tab_bar_right. Command entries resolve on
# the herdr server, so under `herdr --remote` this reports the remote box.
# Portable: Linux and macOS both run it. A failing command leaves the entry blank.
set -eu

if [ -r /proc/loadavg ]; then
  load=$(cut -d' ' -f1 /proc/loadavg)
  cores=$(nproc)
  mem=$(free -m | awk '/^Mem:/ {printf "%.1f/%.1fG", $3/1024, $2/1024}')
  vol=/
else
  load=$(sysctl -n vm.loadavg | awk '{print $2}')
  cores=$(sysctl -n hw.ncpu)
  # Activity Monitor's "Memory Used": app (anonymous - purgeable), wired and compressed.
  mem=$(vm_stat | awk -v t="$(sysctl -n hw.memsize)" '
    /page size of/ { p = $8 }
    /^Anonymous pages/ { a = $3 }
    /^Pages purgeable/ { u = $3 }
    /^Pages wired down/ { w = $4 }
    /^Pages occupied by compressor/ { c = $5 }
    END { printf "%.1f/%.1fG", (a - u + w + c) * p / 1073741824, t / 1073741824 }')
  # / is the sealed system volume; user data is on the Data volume.
  vol=/System/Volumes/Data
fi

disk=$(df -h "$vol" | awk 'NR==2 {print $5}')
load_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN {printf "%d", (l/c)*100}')
printf 'load %s%% · ram %s · disk %s\n' "$load_pct" "$mem" "$disk"
