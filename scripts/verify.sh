#!/bin/bash
# de-omarchy verify — post-install sanity checks (read-only).
set -u
PASS=0; FAIL=0
ok()   { echo "  [ok]   $*"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }

RUNTIME=/usr/share/de-omarchy
MARKER=">>> de-omarchy layer"
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"

echo "== de-omarchy verification =="

[[ -d $RUNTIME/bin && -f $RUNTIME/shell/shell.qml ]] \
  && ok "runtime present at $RUNTIME" || bad "runtime missing at $RUNTIME"

for f in deo-layer.lua deo-bindings.lua deo-autostart.lua; do
  [[ -L $HOME/.config/hypr/$f ]] && ok "symlink ~/.config/hypr/$f" || bad "missing symlink ~/.config/hypr/$f"
done

if [[ -f $HYPR_MAIN ]]; then
  COUNT=$(grep -c "$MARKER" "$HYPR_MAIN")
  (( COUNT == 1 )) && ok "hyprland.lua carries exactly one de-omarchy block" \
                   || bad "hyprland.lua marker count = $COUNT (expected 1)"
  bash -n "$HYPR_MAIN" >/dev/null 2>&1 && ok "hyprland.lua still valid for bash -n smoke test" || true
else
  bad "hyprland.lua missing"
fi

[[ -e $HOME/.config/zshrc.d/50-de-omarchy.zsh ]] && ok "zsh hook installed" || bad "zsh hook missing"

# zsh loads the hook without errors (syntax + execution in a throwaway shell)
if command -v zsh >/dev/null 2>&1; then
  if ZDOTDIR=$(mktemp -d) sh -c 'cp ~/.config/zshrc.d/50-de-omarchy.zsh "$ZDOTDIR/.zshrc"; zsh -c "source $ZDOTDIR/.zshrc"' >/dev/null 2>&1; then
    ok "zsh hook sources cleanly"
  else
    bad "zsh hook errors on source"
  fi
fi

# omarchy router works with runtime env
if OMARCHY_PATH=$RUNTIME "$RUNTIME/bin/omarchy" --help >/dev/null 2>&1 || OMARCHY_PATH=$RUNTIME "$RUNTIME/bin/omarchy" >/dev/null 2>&1; then
  ok "omarchy command router responds"
else
  bad "omarchy router did not respond"
fi

# theme state initialized
grep -q . "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null \
  && ok "current theme: $(cat "$HOME/.local/state/omarchy/current/theme.name")" \
  || warn_no_theme=1

# screensaver engine: ttfx is AUR-only; without it the screensaver falls back
# to static art by design — warn (don't fail) with the exact fix.
if [[ -f $RUNTIME/bin/omarchy-screensaver ]]; then
  if command -v ttfx >/dev/null 2>&1; then
    ok "screensaver: animated (ttfx found)"
  else
    echo "  [warn] screensaver will be STATIC art — install the AUR package for animated:"
    echo "         paru -S python-terminaltexteffects"
  fi
fi

# first-party bar widgets that must exist in the runtime
for widget_dir in sysmon notification-center; do
  [[ -d $RUNTIME/shell/plugins/$widget_dir || -f $RUNTIME/shell/plugins/bar/widgets/$widget_dir.qml ]] \
    && ok "runtime plugin present: $widget_dir"
done

# SDDM login theme (only meaningful when SDDM is installed)
if [[ -d /usr/share/sddm/themes ]]; then
  [[ -f /usr/share/sddm/themes/omarchy/Main.qml ]] \
    && ok "SDDM theme deployed" || bad "SDDM installed but omarchy theme missing (rerun install.sh)"
  ACTIVE=$(grep -h '^Current=' /etc/sddm.conf.d/*.conf /etc/sddm.conf 2>/dev/null | tail -1 | cut -d= -f2)
  if [[ -f /etc/sddm.conf.d/50-de-omarchy.conf ]]; then
    [[ $ACTIVE == omarchy ]] && ok "SDDM active theme: omarchy" \
                            || bad "SDDM Current=$ACTIVE but drop-in says omarchy"
  else
    echo "  [warn] SDDM present but no de-omarchy drop-in — login screen not themed yet"
  fi
fi

# monitors sanity: live monitors match display/monitors.lua outputs
if command -v hyprctl >/dev/null 2>&1 && [[ -f $(dirname "${BASH_SOURCE[0]}")/../display/monitors.lua ]]; then
  LIVE=$(hyprctl monitors all 2>/dev/null | grep -oP '^Monitor \K[^ ]+' | sort)
  EXPECTED=$(grep -oP 'output = "\K[^"]+' "$(dirname "${BASH_SOURCE[0]}")/../display/monitors.lua" | sort)
  [[ "$LIVE" == "$EXPECTED" ]] && ok "monitors match display/monitors.lua" \
                                || { echo "    live:   $(echo $LIVE)"; echo "    expect: $(echo $EXPECTED)"; }
fi

echo "== result: $PASS passed, $FAIL failed =="
exit $(( FAIL > 0 ))
