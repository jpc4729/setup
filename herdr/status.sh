#!/bin/sh
# One line of host vitals for herdr's tab_bar_right. Command entries resolve on
# the herdr server, so under `herdr --remote` this reports the remote box.
# Kept portable: the same config file is read on the macOS client, where a
# failing command would leave the status entry blank instead.
set -eu

if [ -r /proc/loadavg ]; then
  load=$(cut -d' ' -f1 /proc/loadavg)
  cores=$(nproc)
  mem=$(free -m | awk '/^Mem:/ {printf "%.1f/%.1fG", $3/1024, $2/1024}')
else
  load=$(sysctl -n vm.loadavg | awk '{print $2}')
  cores=$(sysctl -n hw.ncpu)
  mem=$(ps -A -o rss= | awk -v t="$(sysctl -n hw.memsize)" \
    '{s+=$1} END {printf "%.1f/%.1fG", s/1048576, t/1073741824}')
fi

disk=$(df -h / | awk 'NR==2 {print $5}')
cpu=$(awk -v l="$load" -v c="$cores" 'BEGIN {printf "%d", (l/c)*100}')
printf 'cpu %s%% · ram %s · disk %s\n' "$cpu" "$mem" "$disk"
