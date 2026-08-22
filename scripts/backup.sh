#!/bin/bash
# de-omarchy backup — COPIES ONLY, deletes/moves/overwrites nothing.
#
# Default: TARGETED snapshot of exactly the paths install.sh may touch plus
# critical identity files (seconds, a few MB).
# Set DEO_BACKUP_FULL=1 to additionally rsync ALL of ~/.config (slow).
set -u

TS=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="${DEO_BACKUP_ROOT:-$HOME/.de-omarchy-backups}/$TS"
mkdir -p "$BACKUP_ROOT/dotfiles"
LOG="$BACKUP_ROOT/backup.log"
log() { echo "[backup $TS] $*" >> "$LOG"; }

# --- 1. Config paths the installer can touch (small, complete copies) -------
for d in hypr zshrc.d kitty quickshell moonrice moonshell; do
  [[ -d $HOME/.config/$d ]] && rsync -a "$HOME/.config/$d" "$BACKUP_ROOT/config/"
done
for f in starship.toml; do
  [[ -f $HOME/.config/$f ]] && cp -a "$HOME/.config/$f" "$BACKUP_ROOT/config/"
done
log "DONE targeted config"

# --- 2. Shell & identity dotfiles -------------------------------------------
for f in .zshrc .zshenv .zprofile .zlogin .zlogout .bashrc .bash_profile \
         .p10k.zsh .gitconfig .profile; do
  [[ -e $HOME/$f ]] && cp -a "$HOME/$f" "$BACKUP_ROOT/dotfiles/"
done
[[ -d $HOME/.zshrc.d ]] && rsync -a "$HOME/.zshrc.d/" "$BACKUP_ROOT/dotfiles/zshrc.d/"
[[ -d $HOME/.ssh ]] && { mkdir -p "$BACKUP_ROOT/dotfiles/.ssh"; rsync -a --exclude='agent/' --exclude='*.agent.*' "$HOME/.ssh/" "$BACKUP_ROOT/dotfiles/.ssh/"; chmod 700 "$BACKUP_ROOT/dotfiles/.ssh"; chmod 600 "$BACKUP_ROOT"/dotfiles/.ssh/* 2>/dev/null; }
log "DONE dotfiles"

# --- 3. Optional full ~/.config sweep ----------------------------------------
if [[ ${DEO_BACKUP_FULL:-0} == 1 ]]; then
  log "START full config rsync"
  rsync -aHAX --stats "$HOME/.config/" "$BACKUP_ROOT/full-config/" >> "$LOG" 2>&1
  log "DONE full config rc=$?"
fi

# --- 4. Package manifests -----------------------------------------------------
pacman -Qqe > "$BACKUP_ROOT/pkg-manifest-explicit.txt"    2>/dev/null
pacman -Qqm > "$BACKUP_ROOT/pkg-manifest-foreign-AUR.txt" 2>/dev/null

# --- 5. Fingerprint ------------------------------------------------------------
{
  echo "# de-omarchy backup fingerprint — $(date)"
  uname -a
  grep PRETTY_NAME /etc/os-release
  echo "session: $XDG_SESSION_TYPE / $XDG_CURRENT_DESKTOP"
  hyprctl monitors all 2>/dev/null | grep -E '^Monitor|^\t[0-9]+x[0-9]+@'
} > "$BACKUP_ROOT/fingerprint.txt" 2>&1

# --- 6. One-file restore bundle --------------------------------------------------
tar czf "$BACKUP_ROOT/critical-small.tar.gz" \
  -C "$HOME" \
  .ssh .zshrc .zshenv .zprofile .bashrc .gitconfig .zshrc.d \
  .config/hypr .config/zshrc.d .config/starship.toml \
  2>> "$LOG" || true
sha256sum "$BACKUP_ROOT/critical-small.tar.gz" > "$BACKUP_ROOT/critical-small.sha256"

{
  echo "== VERIFICATION $TS =="
  du -sh "$BACKUP_ROOT" 2>/dev/null
  echo "file count: $(find "$BACKUP_ROOT" -type f | wc -l)"
} >> "$LOG"

echo "Backup complete: $BACKUP_ROOT ($(du -sh "$BACKUP_ROOT" | cut -f1))"
