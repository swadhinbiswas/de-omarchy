#!/bin/bash
# One-shot system stats sampler for the omarchy.sysmon bar widget.
# Prints a single line:
#   C=<cpu%> M=<mem%> D=<disk%> G=<gpu-temp> T=<cpu-temp> RX=<MB/s down> TX=<MB/s up>
# Stateless: each invocation takes two samples 0.6s apart and derives rates
# from that window, so the QML side owns no previous-counter state and a dead
# sample never poisons the next one.

read -r t0 i0 <<< "$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat 2>/dev/null)"
read -r rx0 tx0 <<< "$(awk 'NR>2{rx+=$2; tx+=$10} END{print rx+0, tx+0}' /proc/net/dev 2>/dev/null)"

sleep 0.6

read -r t1 i1 <<< "$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat 2>/dev/null)"
read -r rx1 tx1 <<< "$(awk 'NR>2{rx+=$2; tx+=$10} END{print rx+0, tx+0}' /proc/net/dev 2>/dev/null)"

dt=$(( t1 - t0 ))
di=$(( i1 - i0 ))
cpu=0
(( dt > 0 )) && cpu=$(( 100 * (dt - di) / dt ))

mem=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if (t > 0) printf "%d", (t-a)*100/t; else print 0}' /proc/meminfo 2>/dev/null)
mem=${mem:-0}

dsk=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
dsk=${dsk:-0}

# GPU temperature: hwmon first (no subprocess cost), nvidia-smi as fallback.
gpu=0
for hm in /sys/class/hwmon/hwmon*/name; do
  hm_name=$(cat "$hm" 2>/dev/null) || continue
  case $hm_name in
    nvidia*|amdgpu|nouveau|radeon)
      hm_dir=${hm%/name}
      hm_temp=$(cat "$hm_dir/temp1_input" 2>/dev/null) || continue
      [[ -n $hm_temp ]] && { gpu=$(( hm_temp / 1000 )); break; }
      ;;
  esac
done
if (( gpu == 0 )) && command -v nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
  gpu=${gpu:-0}
fi

ct=0
for z in /sys/class/thermal/thermal_zone*/temp; do
  zdir=${z%/temp}
  ztype=$(cat "$zdir/type" 2>/dev/null) || continue
  if [[ $ztype == x86_pkg_temp || $ztype == coretemp ]]; then
    ct=$(awk '{printf "%d", $1/1000}' "$z" 2>/dev/null)
    break
  fi
done
ct=${ct:-0}

down=$(awk "BEGIN{printf \"%.1f\", ($rx1-$rx0)/1048576/0.6}")
up=$(awk "BEGIN{printf \"%.1f\", ($tx1-$tx0)/1048576/0.6}")

echo "C=$cpu M=$mem D=$dsk G=$gpu T=$ct RX=$down TX=$up"
