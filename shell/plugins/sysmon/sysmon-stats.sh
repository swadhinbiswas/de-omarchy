#!/bin/bash
prev_cpu=$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8}' /proc/stat)
prev_idle=$(awk '/^cpu /{print $5}' /proc/stat)
prev_rx=$(awk 'NR>2{t+=$2} END{print t+0}' /proc/net/dev)
prev_tx=$(awk 'NR>2{t+=$10} END{print t+0}' /proc/net/dev)
while true; do
  sleep 2
  cur_cpu=$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8}' /proc/stat)
  cur_idle=$(awk '/^cpu /{print $5}' /proc/stat)
  dt=$(( cur_cpu - prev_cpu )); di=$(( cur_idle - prev_idle ))
  if [ "$dt" -gt 0 ]; then cpu=$(( 100 * (dt - di) / dt )); else cpu=0; fi
  prev_cpu=$cur_cpu; prev_idle=$cur_idle
  mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)
  dsk=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
  gpu=0
  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  fi
  gpu=${gpu:-0}
  cputemp=0
  for z in /sys/class/thermal/thermal_zone*/temp; do
    ztype=$(echo $z | sed 's|/temp||;s|.*/||')
    ztype=$(cat /sys/class/thermal/$ztype/type 2>/dev/null)
    if [ "$ztype" = "x86_pkg_temp" ] || [ "$ztype" = "coretemp" ]; then
      cputemp=$(awk '{printf "%d", $1/1000}' $z)
      break
    fi
  done
  if [ "$cputemp" = "0" ]; then
    cputemp=$(awk '{printf "%d", $1/1000}' /sys/class/thermal/thermal_zone3/temp 2>/dev/null)
  fi
  cur_rx=$(awk 'NR>2{t+=$2} END{print t+0}' /proc/net/dev)
  cur_tx=$(awk 'NR>2{t+=$10} END{print t+0}' /proc/net/dev)
  rx_mbps=$(awk "BEGIN{printf \"%.1f\", ($cur_rx-$prev_rx)/1048576}")
  tx_mbps=$(awk "BEGIN{printf \"%.1f\", ($cur_tx-$prev_tx)/1048576}")
  prev_rx=$cur_rx; prev_tx=$cur_tx
  echo "C=$cpu M=$mem D=${dsk:-0} G=$gpu T=$cputemp RX=$rx_mbps TX=$tx_mbps"
done
