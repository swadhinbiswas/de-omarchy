#!/bin/bash
# de-omarchy uninstall — reverses exactly what install.sh added.
# Never deletes anything not created by de-omarchy.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RUNTIME=/usr/share/de-omarchy
BACKUP_ROOT="${DEO_BACKUP_ROOT:-$HOME/.de-omarchy-backups}"
MARKER_START=">>> de-omarchy layer"
MARKER_END="<<< end de-omarchy layer >>>"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

# 1. Remove the appended block from hyprland.lua
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
if [[ -f $HYPR_MAIN ]] && grep -q "$MARKER_START" "$HYPR_MAIN"; then
  TMP=$(mktemp)
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 ~ start, $0 ~ end { next } { print }' "$HYPR_MAIN" > "$TMP"
  if grep -q "deo-layer" "$TMP"; then
    log "WARNING: marker removal looks wrong; hyprland.lua left untouched — restore manually from backup"
  else
    cp -a "$HYPR_MAIN" "$HYPR_MAIN.pre-uninstall.$(date +%Y%m%d%H%M%S)"
    mv "$TMP" "$HYPR_MAIN"
    log "Removed de-omarchy block from hyprland.lua"
  fi
else
  log "hyprland.lua has no de-omarchy block"
fi

# 2. Remove symlinks that point into this repo (only ours)
remove_link() {
  local path=$1
  if [[ -L $path ]] && readlink "$path" | grep -qE '^'"$REPO_DIR"'|de-omarchy'; then
    rm "$path"
    log "removed symlink: $path"
  fi
}
remove_link "$HOME/.config/hypr/deo-layer.lua"
remove_link "$HOME/.config/hypr/deo-bindings.lua"
remove_link "$HOME/.config/hypr/deo-autostart.lua"
remove_link "$HOME/.config/zshrc.d/50-de-omarchy.zsh"

# 3. Remove runtime + env file
if [[ -d $RUNTIME ]]; then
  sudo rm -rf "$RUNTIME"
  log "removed $RUNTIME"
fi
[[ -f /etc/environment.d/10-de-omarchy.conf ]] \
  && sudo rm /etc/environment.d/10-de-omarchy.conf \
  && log "removed /etc/environment.d/10-de-omarchy.conf"

log "Done. Your desktop is back to the pre-de-omarchy state after 'hyprctl reload'."
log "Full snapshot backups remain in: $BACKUP_ROOT"
