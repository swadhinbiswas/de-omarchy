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
         ~/.config/hypr/{deo-layer,deo-bindings,deo-autostart}.lua  (symlinks -> runtime)
         ~/.config/hypr/hyprland.lua                                (marked block APPENDED)
         ~/.config/zshrc.d/50-de-omarchy.zsh                        (symlink -> runtime;
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
if (( ! SKIP_PACKAGES )); then
  log "Checking UI packages"
  MISSING=()
  while read -r pkg; do
    [[ -z $pkg || $pkg == \#* ]] && continue
    pacman -Qi "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
  done < "$REPO_DIR/packages/ui.packages"

  if (( ${#MISSING[@]} == 0 )); then
    log "All UI packages already present"
  else
    log "Installing missing UI packages: ${MISSING[*]}"
    # Repo packages first, in ONE transaction (single sudo prompt).
    REPO_PKGS=()
    for pkg in "${MISSING[@]}"; do
      pacman -Si "$pkg" >/dev/null 2>&1 && REPO_PKGS+=("$pkg")
    done
    (( ${#REPO_PKGS[@]} > 0 )) && sudo pacman -S --needed --noconfirm "${REPO_PKGS[@]}"

    # Whatever remains is AUR-only: per package, with piped answers so
    # prompts (provider selection etc.) never eat our package list.
    # --skipreview is paru-specific; yay rejects unknown flags.
    AUR_FLAGS=(-S --needed --noconfirm)
    [[ $AUR_HELPER == paru ]] && AUR_FLAGS+=(--skipreview)
    FAILED=""
    for pkg in "${MISSING[@]}"; do
      pacman -Qi "$pkg" >/dev/null 2>&1 && continue
      if [[ -n $AUR_HELPER ]]; then
        log "Installing AUR package: $pkg ($AUR_HELPER)"
        if (( ASSUME_YES )); then
          "$AUR_HELPER" "${AUR_FLAGS[@]}" "$pkg" </dev/null || FAILED+="$pkg "
        else
          printf 'y\n' | "$AUR_HELPER" "${AUR_FLAGS[@]}" "$pkg" || FAILED+="$pkg "
        fi
      else
        FAILED+="$pkg "
      fi
    done
    [[ -n ${FAILED:-} ]] && warn "could not auto-install: $FAILED (install manually; desktop works without them)"
  fi
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
  "$REPO_DIR/keybindings" "$REPO_DIR/plugin-library" \
  "$REPO_DIR/monitor-manager" \
  "$REPO_DIR/packages" \
  "$REPO_DIR/registry.json" "$REPO_DIR/logo.txt" "$REPO_DIR/icon.txt" \
  "$RUNTIME/"
sudo chmod +x "$RUNTIME"/bin/* 2>/dev/null || true

log "Writing /etc/environment.d/10-de-omarchy.conf"
sudo mkdir -p /etc/environment.d
printf 'OMARCHY_PATH=%s\n' "$RUNTIME" | sudo tee /etc/environment.d/10-de-omarchy.conf >/dev/null

# Symlink key commands into /usr/bin so sudo/polkit can find them (omarchy-dns
# requires root, and the shell IPC commands need to be on the system PATH).
log "Symlinking key commands to /usr/bin"
for cmd in omarchy-dns omarchy-menu omarchy-shell omarchy-theme-set omarchy-theme-list \
           omarchy-theme-bg-set omarchy-theme-bg-next omarchy-theme-refresh \
           omarchy-capture-screenshot omarchy-capture-region omarchy-capture-text \
           omarchy-system-lock omarchy-restart-shell omarchy-keybindings omarchy-plugin-manager; do
  [[ -f "$RUNTIME/bin/$cmd" ]] && sudo ln -sf "$RUNTIME/bin/$cmd" "/usr/bin/$cmd" 2>/dev/null
done

# ----------------------------------------------------------------------------
# 5. User config hooks (additive only)
# ----------------------------------------------------------------------------
log "Installing user config hooks"

# Symlinks point at the RUNTIME copy, never at this git checkout: after
# install, the desktop must keep working even if the repo is moved or deleted.
# The runtime copies are refreshed by every install.sh / rsync run.
mkdir -p "$HOME/.config/hypr" "$HOME/.config/zshrc.d"

ln -sfn "$RUNTIME/config/hypr/deo-layer.lua"     "$HOME/.config/hypr/deo-layer.lua"
ln -sfn "$RUNTIME/config/hypr/deo-bindings.lua"  "$HOME/.config/hypr/deo-bindings.lua"
ln -sfn "$RUNTIME/config/hypr/deo-autostart.lua" "$HOME/.config/hypr/deo-autostart.lua"
ln -sfn "$RUNTIME/config/zshrc.d/50-de-omarchy.zsh" "$HOME/.config/zshrc.d/50-de-omarchy.zsh"

# Default omarchy user-state config (extensions/hooks/themed) — never overwrite.
if [[ -d $REPO_DIR/config/omarchy ]]; then
  mkdir -p "$HOME/.config/omarchy"
  rsync -a --ignore-existing "$REPO_DIR/config/omarchy/" "$HOME/.config/omarchy/"
fi

# Deploy terminal/starship/nvim/opencode configs (only if user doesn't have them)
log "Deploying UI configs (never overwrites existing)"
for pair in "kitty/kitty.conf:.config/kitty/kitty.conf" "starship/starship.toml:.config/starship.toml" "opencode/opencode.jsonc:.config/opencode/opencode.jsonc"; do
  src="$REPO_DIR/config/${pair%%:*}"
  dst="$HOME/${pair##*:}"
  if [[ -f $src ]] && [[ ! -f $dst ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log "deployed $dst"
  fi
done
# Neovim config: rsync with ignore-existing (preserves user's plugins/config)
if [[ -d $REPO_DIR/config/nvim ]]; then
  mkdir -p "$HOME/.config/nvim"
  rsync -a --ignore-existing "$REPO_DIR/config/nvim/" "$HOME/.config/nvim/"
fi

# CapsLock emoji compose sequences — only when the user has no XCompose of
# their own. The include points at the runtime copy, so theme-independent.
XCOMPOSE="$HOME/.XCompose"
if [[ ! -f $XCOMPOSE && -f "$RUNTIME/default/xcompose" ]]; then
  printf 'include "%s"\n' "$RUNTIME/default/xcompose" > "$XCOMPOSE"
  log "deployed $XCOMPOSE (CapsLock emoji compose; delete to opt out)"
fi

# Voxtype dictation config template — same never-overwrite rule as above.
VOXTYPE_CFG="$HOME/.config/voxtype/config.toml"
if [[ ! -f $VOXTYPE_CFG && -f "$RUNTIME/default/voxtype/config.toml" ]]; then
  mkdir -p "$(dirname "$VOXTYPE_CFG")"
  cp "$RUNTIME/default/voxtype/config.toml" "$VOXTYPE_CFG"
  log "deployed $VOXTYPE_CFG"
fi

# Branding art for the About window and screensaver — never-overwrite: the
# user's edits (omarchy branding …) survive reinstalls. Without these the
# branding editors fail with "no such file or directory" and the screensaver
# has nothing to draw.
if [[ -f "$RUNTIME/logo.txt" ]]; then
  mkdir -p "$HOME/.config/omarchy/branding"
  for art in screensaver:logo.txt about:icon.txt; do
    dst_name=${art%%:*}; src_name=${art##*:}
    dst="$HOME/.config/omarchy/branding/$dst_name.txt"
    if [[ ! -f $dst ]]; then
      cp "$RUNTIME/$src_name" "$dst"
      log "deployed $dst"
    fi
  done
fi

# AI agent skills: symlink the bundled Omarchy/diagnose-crash skills into
# every known agent skill directory (same loop omarchy-provision-user runs;
# safe to re-run, ln -sfn is idempotent).
if [[ -d $RUNTIME/default/agents/skills ]]; then
  log "Linking agent skills"
  mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" \
    "$HOME/.pi/agent/skills" "$HOME/.gemini/config/skills"
  for skill_dir in "$RUNTIME"/default/agents/skills/*/; do
    skill_name=${skill_dir%/}
    skill_name=${skill_name##*/}
    ln -sfn "$skill_dir" "$HOME/.agents/skills/$skill_name"
    ln -sfn "$skill_dir" "$HOME/.claude/skills/$skill_name"
    ln -sfn "$skill_dir" "$HOME/.codex/skills/$skill_name"
    ln -sfn "$skill_dir" "$HOME/.pi/agent/skills/$skill_name"
    ln -sfn "$skill_dir" "$HOME/.gemini/config/skills/$skill_name"
  done
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
# 6. PAM config for Omarchy shell lock screen
# ----------------------------------------------------------------------------
if [[ ! -f /etc/pam.d/omarchy-lock-password ]]; then
  log "Installing PAM config for Omarchy shell lock"
  sudo cp "$REPO_DIR/config/pam/omarchy-lock-password" /etc/pam.d/omarchy-lock-password
  sudo chmod 644 /etc/pam.d/omarchy-lock-password
fi

# ----------------------------------------------------------------------------
# 6b. SDDM login screen — upstream's Omarchy greeter (only if SDDM installed)
#
# Additive by design: the theme lands in its own dir under themes/, and the
# settings arrive as a NEW drop-in file named to sort AFTER any existing
# /etc/sddm.conf.d/*.conf, so Current=omarchy wins without editing anything.
# Deleting our drop-in (or running uninstall.sh) restores the previous theme
# untouched. Requires no display-manager binaries or PAM changes.
# ----------------------------------------------------------------------------
if [[ -d /usr/share/sddm/themes && -f /etc/pam.d/sddm ]]; then
  log "Installing SDDM login theme (Omarchy greeter on Hyprland)"
  sudo rm -rf /usr/share/sddm/themes/omarchy
  sudo cp -r "$RUNTIME/default/sddm/omarchy" /usr/share/sddm/themes/omarchy
  sudo install -m 644 "$RUNTIME/default/sddm/hyprland.lua" /usr/share/sddm/hyprland.lua
  printf '%s\n' \
    '[Theme]' 'Current=omarchy' \
    '' \
    '[General]' 'DisplayServer=wayland' \
    '' \
    '[Wayland]' \
    'CompositorCommand=start-hyprland -- --config /usr/share/sddm/hyprland.lua' \
    | sudo tee /etc/sddm.conf.d/50-de-omarchy.conf >/dev/null
else
  log "SDDM not detected — skipping login theme"
fi

# ----------------------------------------------------------------------------
# 7. Clean up stale host config (additive: comments out dead code)
# ----------------------------------------------------------------------------
log "Cleaning up stale host config"

# Remove stale zsh files from old shell ecosystem
for stale in moonrice.zsh dots-hyprland.zsh auto-Hypr.sh; do
  [[ -f "$HOME/.config/zshrc.d/$stale" ]] && rm "$HOME/.config/zshrc.d/$stale" && log "removed stale zsh: $stale"
done

# Repoint dead moonshell:* keymap targets at Omarchy equivalents
bash "$REPO_DIR/scripts/migrate-host-binds.sh"

# ----------------------------------------------------------------------------
# 8. Omarchy state init + default theme (first install only)
# ----------------------------------------------------------------------------
export OMARCHY_PATH=$RUNTIME
if grep -q . "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null; then
  log "Omarchy state already initialized — keeping theme '$(cat "$HOME/.local/state/omarchy/current/theme.name")'"
else
  log "Initializing Omarchy state + rose-pine theme"
  mkdir -p "$HOME/.local/state/omarchy/current"
  "$RUNTIME/bin/omarchy-theme-set" rose-pine || warn "theme set failed (non-fatal; run 'omarchy theme set <name>' later)"
fi

unset OMARCHY_PATH

# ----------------------------------------------------------------------------
# 9. Done
# ----------------------------------------------------------------------------
log "Verifying installation"
bash "$REPO_DIR/scripts/verify.sh" || warn "verification reported issues above"

cat <<DONE

  de-omarchy installed.

  If your desktop was ALREADY running before this install, apply the new
  runtime now (this picks up shell/QML changes too):
      omarchy-restart-shell
      hyprctl reload

  Full experience after next login (env vars settle everywhere).
  Themes:   omarchy theme list   |   omarchy theme set "Tokyo Night"
  Menu:     SUPER + SHIFT + M    (upstream's SUPER+SPACE stays yours)
  Screensaver: idle for ~2.5 min — animated via ttfx if python-terminaltexteffects
               installed; static art otherwise (see any warning above).
  Revert:   ./uninstall.sh       (restores the exact pre-install state)

DONE
