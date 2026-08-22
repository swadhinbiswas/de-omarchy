#!/bin/bash
# ============================================================================
#  de-omarchy installer — Omarchy look & feel for any Arch-based system
#
#  Safety model:
#    * backs up everything BEFORE touching anything (outside this repo)
#    * never deletes or overwrites an existing user config; new files are
#      added, one clearly-marked block is APPENDED to hyprland.lua
#    * idempotent: safe to re-run
#    * fully reversible: uninstall.sh undoes every change made here
#  It never touches pacman.conf, kernels, bootloaders, mirrors or repos.
# ============================================================================
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RUNTIME=/usr/share/de-omarchy
BACKUP_ROOT="${DEO_BACKUP_ROOT:-$HOME/.de-omarchy-backups}"
MARKER_START=">>> de-omarchy layer"
MARKER_END="<<< end de-omarchy layer >>>"

log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m ->\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ----------------------------------------------------------------------------
# 1. Preflight
# ----------------------------------------------------------------------------
[[ $EUID -eq 0 ]] && die "Run as your normal user (sudo is invoked when needed)."

[[ -r /etc/os-release ]] || die "/etc/os-release not found — not an Arch-based system?"
. /etc/os-release
case ${ID_LIKE:-} in
  *arch*) ;; *) [[ ${ID:-} == arch ]] || die "This looks like '${ID:-unknown}', de-omarchy targets Arch-based distros." ;;
esac

for cmd in git rsync curl; do command -v $cmd >/dev/null 2>&1 || die "missing command: $cmd"; done

AUR_HELPER=""
for h in paru yay; do command -v $h >/dev/null 2>&1 && { AUR_HELPER=$h; break; }; done

ASSUME_YES=0
SKIP_BACKUP=0
SKIP_PACKAGES=0
for arg in "$@"; do
  case $arg in
    -y|--yes) ASSUME_YES=1 ;;
    --skip-backup) SKIP_BACKUP=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    *) warn "unknown option: $arg" ;;
  esac
done

cat <<BANNER

  de-omarchy — apply the Omarchy desktop look on top of $(printf '%s' "${PRETTY_NAME:-this system}")

  What happens:
    1. TARGETED backup (seconds): every file this installer could touch,
       plus .ssh / zsh stack / starship — -> $BACKUP_ROOT/<timestamp>/
       (add DEO_BACKUP_FULL=1 to also snapshot all of ~/.config)
    2. Missing UI packages installed (system layer untouched)
    3. Runtime deployed to $RUNTIME
    4. Additive user config hooks installed:
         ~/.config/hypr/{deo-layer,deo-bindings,deo-autostart}.lua  (new symlinks)
         ~/.config/hypr/hyprland.lua                                (marked block APPENDED)
         ~/.config/zshrc.d/50-de-omarchy.zsh                        (new symlink;
          your .zshrc already sources this dir — zero edits to .zshrc)
    5. Omarchy state initialized + rose-pine theme applied

  NOTHING in your home directory is ever deleted or overwritten:
    * new files are only ADDED (symlinks into this repo)
    * hyprland.lua gets one clearly-marked block APPENDED; a timestamped
      copy of it is saved next to it first
    * existing ~/.config/omarchy state is merged with --ignore-existing
  NOT touched: .zshrc/.zshenv/starship.toml/kitty.conf/ssh keys, pacman.conf,
  mirrors, kernel, bootloader, display manager, monitors layout.

BANNER

if (( ! ASSUME_YES )); then
  read -rp "Proceed? [y/N] " answer
  [[ $answer =~ ^[Yy]$ ]] || die "aborted by user"
fi

# ----------------------------------------------------------------------------
# 2. Backup (Phase 0 — always first)
# ----------------------------------------------------------------------------
if (( SKIP_BACKUP )); then
  warn "skipping backup (--skip-backup) — NOT recommended"
else
  log "Creating timestamped backup"
  DEO_BACKUP_ROOT=$BACKUP_ROOT bash "$REPO_DIR/scripts/backup.sh"
fi
LATEST_BACKUP=$(ls -1dt "$BACKUP_ROOT"/*/ 2>/dev/null | head -1 || true)
[[ -n $LATEST_BACKUP ]] || die "backup missing after backup step — aborting"
log "Backup ready: $LATEST_BACKUP"

# ----------------------------------------------------------------------------
# 3. Packages (UI layer only, missing ones only)
# ----------------------------------------------------------------------------
install_pkg() {
  local pkg=$1
  if pacman -Qi "$pkg" >/dev/null 2>&1; then return 0; fi
  if sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  if [[ -n $AUR_HELPER ]]; then
    "$AUR_HELPER" -S --needed "$pkg"
  else
    warn "no AUR helper found; install '$pkg' manually (paru/yay)"
    return 1
  fi
}

if (( ! SKIP_PACKAGES )); then
  log "Installing missing UI packages (this can take a while)"
  FAILED=""
  while read -r pkg; do
    [[ -z $pkg || $pkg == \#* ]] && continue
    install_pkg "$pkg" || FAILED+="$pkg "
  done < "$REPO_DIR/packages/ui.packages"
  [[ -n $FAILED ]] && warn "could not auto-install: $FAILED (the desktop still works if these were optional)"
fi

command -v quickshell >/dev/null 2>&1 || die "quickshell is required but not installed"

# ----------------------------------------------------------------------------
# 4. Runtime deployment to $RUNTIME
# ----------------------------------------------------------------------------
log "Deploying runtime to $RUNTIME"
sudo mkdir -p "$RUNTIME"
sudo rsync -a --delete \
  "$REPO_DIR/bin" "$REPO_DIR/shell" "$REPO_DIR/themes" \
  "$REPO_DIR/applications" "$REPO_DIR/default" "$REPO_DIR/config" \
  "$RUNTIME/"
sudo chmod +x "$RUNTIME"/bin/* 2>/dev/null || true

log "Writing /etc/environment.d/10-de-omarchy.conf"
printf 'OMARCHY_PATH=%s\n' "$RUNTIME" | sudo tee /etc/environment.d/10-de-omarchy.conf >/dev/null

# ----------------------------------------------------------------------------
# 5. User config hooks (additive only)
# ----------------------------------------------------------------------------
log "Installing user config hooks"

mkdir -p "$HOME/.config/hypr" "$HOME/.config/zshrc.d"

ln -sfn "$REPO_DIR/config/hypr/deo-layer.lua"     "$HOME/.config/hypr/deo-layer.lua"
ln -sfn "$REPO_DIR/config/hypr/deo-bindings.lua"  "$HOME/.config/hypr/deo-bindings.lua"
ln -sfn "$REPO_DIR/config/hypr/deo-autostart.lua" "$HOME/.config/hypr/deo-autostart.lua"
ln -sfn "$REPO_DIR/config/zshrc.d/50-de-omarchy.zsh" "$HOME/.config/zshrc.d/50-de-omarchy.zsh"

# Default omarchy user-state config (extensions/hooks/themed) — never overwrite.
if [[ -d $REPO_DIR/config/omarchy ]]; then
  mkdir -p "$HOME/.config/omarchy"
  rsync -a --ignore-existing "$REPO_DIR/config/omarchy/" "$HOME/.config/omarchy/"
fi

# Append the marked activation block to hyprland.lua (idempotent).
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
if [[ ! -f $HYPR_MAIN ]]; then
  die "~/.config/hypr/hyprland.lua not found — install/configure Hyprland first (or point me at your entry config)"
fi
if grep -q "$MARKER_START" "$HYPR_MAIN"; then
  log "hyprland.lua already carries the de-omarchy block — skipping append"
else
  cp -a "$HYPR_MAIN" "$HYPR_MAIN.pre-de-omarchy.$(date +%Y%m%d%H%M%S)"
  cat "$REPO_DIR/config/hypr/append-block.lua" >> "$HYPR_MAIN"
  log "Appended de-omarchy block to $HYPR_MAIN (pre-change copy saved next to it)"
fi

# ----------------------------------------------------------------------------
# 6. Omarchy state init + default theme
# ----------------------------------------------------------------------------
log "Initializing Omarchy state + rose-pine theme"
export OMARCHY_PATH=$RUNTIME
mkdir -p "$HOME/.local/state/omarchy/current"
"$RUNTIME/bin/omarchy-theme-set" rose-pine || warn "theme set failed (non-fatal; run 'omarchy theme set <name>' later)"

unset OMARCHY_PATH

# ----------------------------------------------------------------------------
# 7. Done
# ----------------------------------------------------------------------------
log "Verifying installation"
bash "$REPO_DIR/scripts/verify.sh" || warn "verification reported issues above"

cat <<DONE

  de-omarchy installed.

  Try it now (without logging out):
      source ~/.config/zshrc.d/50-de-omarchy.zsh
      hyprctl reload

  Full experience after next login (env vars settle everywhere).
  Themes:   omarchy theme list   |   omarchy theme set "Tokyo Night"
  Menu:     SUPER + SHIFT + M    (upstream's SUPER+SPACE stays yours)
  Revert:   ./uninstall.sh       (restores the exact pre-install state)

DONE
