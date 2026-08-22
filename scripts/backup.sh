#!/bin/bash
# de-omarchy backup — COPIES ONLY. Never deletes, moves or overwrites anything.
# Writes to $DEO_BACKUP_ROOT (default ~/.de-omarchy-backups), outside the repo.
set -u

TS=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="${DEO_BACKUP_ROOT:-$HOME/.de-omarchy-backups}/$TS"
mkdir -p "$BACKUP_ROOT"
LOG="$BACKUP_ROOT/backup.log"
log() { echo "[backup $TS] $*" >> "$LOG"; }

log "START config rsync"
rsync -aHAX --stats "$HOME/.config/" "$BACKUP_ROOT/config/" >> "$LOG" 2>&1
log "DONE config rc=$?"

# Shell & identity dotfiles
mkdir -p "$BACKUP_ROOT/dotfiles"
for f in .zshrc .zshenv .zprofile .zlogin .zlogout .bashrc .bash_profile .bash_logout \
         .p10k.zsh .gitconfig .gitignore_global .tmux.conf .profile; do
  [[ -e $HOME/$f ]] && cp -a "$HOME/$f" "$BACKUP_ROOT/dotfiles/"
done
[[ -d $HOME/.zshrc.d ]] && rsync -a "$HOME/.zshrc.d/" "$BACKUP_ROOT/dotfiles/zshrc.d/"
[[ -d $HOME/.ssh ]] && { mkdir -p "$BACKUP_ROOT/dotfiles/.ssh"; rsync -a "$HOME/.ssh/" "$BACKUP_ROOT/dotfiles/.ssh/"; chmod 700 "$BACKUP_ROOT/dotfiles/.ssh"; chmod 600 "$BACKUP_ROOT"/dotfiles/.ssh/* 2>/dev/null; }
log "DONE dotfiles"

# Relevant ~/.local/share subfolders only (themes, fonts, app data stays out)
for d in applications fonts icons themes backgrounds sounds wayland hypr swww matugen color-schemes wallpapers; do
  [[ -d $HOME/.local/share/$d ]] && rsync -a "$HOME/.local/share/$d" "$BACKUP_ROOT/local-share/"
done
log "DONE local-share relevant"

# Package manifests
pacman -Qq   > "$BACKUP_ROOT/pkg-manifest-all.txt"        2>/dev/null
pacman -Qqe  > "$BACKUP_ROOT/pkg-manifest-explicit.txt"   2>/dev/null
pacman -Qqm  > "$BACKUP_ROOT/pkg-manifest-foreign-AUR.txt" 2>/dev/null
flatpak list --app --columns=application > "$BACKUP_ROOT/pkg-manifest-flatpak.txt" 2>/dev/null || true
log "DONE package manifests"

# Environment fingerprint
{
  echo "# de-omarchy backup fingerprint — $(date)"
  echo "## kernel"; uname -a
  echo "## os-release"; cat /etc/os-release
  echo "## session"; echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP SHELL=$SHELL"
  echo "## display-manager"; systemctl status display-manager.service --no-pager 2>&1 | head -4
  echo "## hyprctl monitors"; hyprctl monitors all 2>/dev/null
} > "$BACKUP_ROOT/fingerprint.txt" 2>&1

# Small critical bundle for quick restore
tar czf "$BACKUP_ROOT/critical-small.tar.gz" \
  -C "$HOME" \
  .ssh .zshrc .zshenv .zprofile .bashrc .gitconfig .zshrc.d \
  .config/starship.toml .config/hypr .config/zshrc.d \
  2>> "$LOG" || true
sha256sum "$BACKUP_ROOT/critical-small.tar.gz" > "$BACKUP_ROOT/critical-small.sha256"

# Verification summary
{
  echo "== VERIFICATION $TS =="
  du -sh "$BACKUP_ROOT/config" "$BACKUP_ROOT/dotfiles" "$BACKUP_ROOT/local-share" 2>/dev/null
  echo "file count: $(find "$BACKUP_ROOT" -type f | wc -l)"
  echo "critical tar: $(stat -c%s "$BACKUP_ROOT/critical-small.tar.gz") bytes"
} >> "$LOG"

echo "Backup complete: $BACKUP_ROOT"
