#!/bin/bash
# sysmon-stats.sh — outputs "C=cpu M=mem D=disk G=gpu RX=down TX=up" every 2 seconds
prev_cpu=$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8}' /proc/stat)
prev_idle=$(awk '/^cpu /{print $5}' /proc/stat)
while true; do
  sleep 1
  cur_cpu=$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8}' /proc/stat)
  cur_idle=$(awk '/^cpu /{print $5}' /proc/stat)
  dt=$(( cur_cpu - prev_cpu ))
  di=$(( cur_idle - prev_idle ))
  if [ "$dt" -gt 0 ]; then cpu=$(( 100 * (dt - di) / dt )); else cpu=0; fi
  prev_cpu=$cur_cpu
  prev_idle=$cur_idle
  mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)
  dsk=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
  gpu=0
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  fi
  gpu=${gpu:-0}
  rx=$(awk 'NR>2{t+=$2} END{printf "%.1f", t/1048576}' /proc/net/dev)
  tx=$(awk 'NR>2{t+=$10} END{printf "%.1f", t/1048576}' /proc/net/dev)
  echo "C=$cpu M=$mem D=${dsk:-0} G=$gpu RX=$rx TX=$tx"
done
