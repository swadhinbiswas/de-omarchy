#!/bin/bash
# ============================================================================
#  migrate-host-binds.sh — repoint dead host keymap targets at Omarchy
#
#  For setups like "Moonrice" whose Hyprland Lua keymap dispatches to a
#  removed shell (global("moonshell:*") IPC calls), this rewrites those
#  entries to live de-omarchy equivalents. Idempotent: skips when nothing
#  matches. Always backs up the file next to itself first.
#
#  Also comments out dead autostart lines in hyprland/execs.lua:
#    wallpaper daemon, moonshell/waybar fallback, hypridle
# ============================================================================
set -euo pipefail

KEYMAP="$HOME/.config/hypr/keymap.lua"
EXECS="$HOME/.config/hypr/hyprland/execs.lua"
STAMP=$(date +%Y%m%d%H%M%S)

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if [[ -f $KEYMAP ]] && sed -n '/^[[:space:]]*--/d; p' "$KEYMAP" | grep -q 'moonshell:'; then
  cp -a "$KEYMAP" "$KEYMAP.pre-de-omarchy.$STAMP"
  # Launcher keys -> Omarchy app drawer
  sed -i 's|dsp = global("moonshell:launcher")|dsp = exec("omarchy-menu toggle apps")|g' "$KEYMAP"
  sed -i 's|desc = "Launcher (alias)"|desc = "App drawer"|g' "$KEYMAP"
  sed -i 's|desc = "Launcher", flags|desc = "App drawer", flags|g' "$KEYMAP"
  # Session menu -> system/power menu; utilities -> toggles menu
  sed -i 's|dsp = global("moonshell:session")|dsp = exec("omarchy-menu toggle system")|g' "$KEYMAP"
  sed -i 's|dsp = global("moonshell:utilities")|dsp = exec("omarchy-menu toggle toggle")|g' "$KEYMAP"
  # No equivalent yet: comment the whole line out
  for dead in dashboard sidebar nexus showall; do
    sed -i "s|^k\[#k + 1\].*moonshell:$dead.*|-- [de-omarchy] moonshell gone: &|" "$KEYMAP"
  done
  # Wallpaper / theme switcher scripts called dead daemons/binaries
  sed -i 's|exec(S .. "/wallpaper.sh select")|exec("omarchy-menu toggle background")|g; s|desc = "Wallpaper picker"|desc = "Background switcher"|g' "$KEYMAP"
  sed -i 's|exec(S .. "/wallpaper.sh random")|exec("omarchy-theme-bg-next")|g; s|desc = "Random wallpaper"|desc = "Next background"|g' "$KEYMAP"
  sed -i 's|exec(S .. "/theme-switcher.sh")|exec("omarchy-menu toggle theme")|g; s|desc = "Theme switcher"|desc = "Theme menu"|g' "$KEYMAP"
  log "keymap.lua migrated (backup: $KEYMAP.pre-de-omarchy.$STAMP)"
else
  log "keymap.lua clean or absent — no bind migration needed"
fi

if [[ -f $EXECS ]] && ! grep -q 'de-omarchy' "$EXECS"; then
  cp -a "$EXECS" "$EXECS.pre-de-omarchy.$STAMP"
  # Wallpaper daemon (shell renders natively)
  sed -i '\|scripts/wallpaper.sh|s|^|-- [de-omarchy] |' "$EXECS"
  sed -i '\|vars.shellCmd|s|^|-- [de-omarchy] |' "$EXECS"
  sed -i '\|pgrep -x hypridle|s|^|-- [de-omarchy] |' "$EXECS"
  log "execs.lua dead autostarts commented (backup: $EXECS.pre-de-omarchy.$STAMP)"
else
  log "execs.lua already migrated or absent"
fi
