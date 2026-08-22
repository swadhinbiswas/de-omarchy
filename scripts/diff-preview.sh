#!/bin/bash
# de-omarchy diff-preview — DRY RUN: shows exactly what install.sh would change.
# Changes NOTHING on the system.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=/usr/share/de-omarchy
MARKER=">>> de-omarchy layer"
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"

echo "== 1. Packages that would be installed (missing only) =="
while read -r pkg; do
  [[ -z $pkg || $pkg == \#* ]] && continue
  pacman -Qi "$pkg" >/dev/null 2>&1 && echo "  [have] $pkg" || echo "  [MISSING] $pkg"
done < "$REPO_DIR/packages/ui.packages"

echo
echo "== 2. Runtime deployment =="
if [[ -d $RUNTIME ]]; then
  echo "  [update existing] $RUNTIME  (rsync -a --delete of bin/shell/themes/applications/default/config)"
else
  echo "  [create] $RUNTIME"
fi

echo
echo "== 3. User config symlinks =="
for pair in \
  "$REPO_DIR/config/hypr/deo-layer.lua|$HOME/.config/hypr/deo-layer.lua" \
  "$REPO_DIR/config/hypr/deo-bindings.lua|$HOME/.config/hypr/deo-bindings.lua" \
  "$REPO_DIR/config/hypr/deo-autostart.lua|$HOME/.config/hypr/deo-autostart.lua" \
  "$REPO_DIR/config/zshrc.d/50-de-omarchy.zsh|$HOME/.config/zshrc.d/50-de-omarchy.zsh"; do
  src=${pair%%|*}; dst=${pair##*|}
  if [[ -L $dst ]]; then echo "  [relink] $dst -> $(readlink "$dst")"; else echo "  [new]    $dst -> $src"; fi
done

echo
echo "== 4. hyprland.lua append =="
if [[ ! -f $HYPR_MAIN ]]; then
  echo "  !! $HYPR_MAIN not found"
elif grep -q "$MARKER" "$HYPR_MAIN"; then
  echo "  [skip] block already present"
else
  echo "  [append] the following block to the END of $HYPR_MAIN:"
  sed 's/^/    | /' "$REPO_DIR/config/hypr/append-block.lua"
fi

echo
echo "== 5. Files NOT touched =="
cat <<'EOF'
  ~/.zshrc ~/.zshenv ~/.zprofile        (untouched; hook rides existing zshrc.d glob)
  ~/.config/starship.toml               (untouched)
  ~/.config/kitty/kitty.conf            (untouched)
  ~/.ssh/*                              (untouched, backed up only)
  pacman.conf / mirrors / kernel / bootloader / display manager
EOF
