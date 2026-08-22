# MAPPING — subsystem diff & conflict resolution

Resolution legend:
- **ADOPT** = take Omarchy's tool/config, layer user values on top
- **KEEP** = user's tool stays, restyled only if trivially safe
- **MERGE** = additive combination
- Conflicts resolved in favor of the USER's existing binding (brief rule).

| Subsystem | Omarchy default | User's current setup | Conflict? | Resolution |
|---|---|---|---|---|
| Compositor config | Lua modules under `$OMARCHY_PATH/default/hypr/` loaded by `hyprland.lua` | Moonrice Lua modules in `~/.config/hypr/` | Same mechanism, different layers | **MERGE**: keep host file; append one marked block loading de-omarchy layer last. Revert = delete block. |
| Visual look & feel | gaps 5/10, border 2, rounding 0, no blur/shadow, Omarchy animation set | gaps 2/0, rounding 10, blur on, shadows on, Rosé Pine borders, custom anims | Yes (visual) | **ADOPT** (user asked for the Omarchy look). Host general.lua loads first; ours overrides. Documented visual change. |
| Desktop shell | Quickshell shell from `$OMARCHY_PATH/shell` | moonshell (`qs -c moonshell`) + waybar/swaync fallback | Yes (two shells) | **ADOPT** with bridge: autostart stops moonshell instance, launches omarchy shell supervisor. No host files edited. |
| Launcher/menu | In-shell `omarchy.menu` (SUPER+SPACE upstream) | moonshell launcher (SUPER tap, M, D) + rofi actions | Key conflict on SUPER+SPACE | User keeps SUPER+SPACE (float toggle). Omarchy menu → **SUPER+SHIFT+M**; apps menu SUPER+ALT+SPACE. |
| Notifications | Shell-native via IPC | swaync installed but moonshell handles toasts | None once shell adopted | **ADOPT** shell notifications; binds added only for free keys (SUPER+comma family minus SHIFT+COMMA which is user's playerctl prev). |
| Lock / idle | Shell idle service drives hyprlock; timers in shell.json | hypridle+hyprlock owned by user scripts (shell lock crashed historically) | Double-daemon risk | **MERGE**: bridge pkills host hypridle at startup so shell owns timing; user's hyprlock.conf remains the lock UI. Reverting restores old behavior automatically. |
| Screenshots | `omarchy-capture-screenshot` (PRINT etc.) | screenshot.sh on F6 / SUPER+CTRL+S | PRINT free; SUPER+CTRL+S taken | User keeps F6 + SUPER+CTRL+S; Omarchy adds PRINT, ALT+PRINT, SUPER+PRINT (picker), SUPER+CTRL+PRINT (OCR). |
| Clipboard manager | Shell clipboard panel (SUPER+CTRL+V) | cliphist rofi script on SUPER+V | SUPER+V taken | Both coexist: user keeps SUPER+V script; shell panel reachable via menu and SUPER+CTRL+V (added). Watcher processes deduped by bridge. |
| Terminal emulator | kitty themed via templates | kitty already configured (Rosé Pine Moon, JetBrains Mono, custom maps) | Config style differs | **KEEP** user's kitty.conf byte-for-byte. Optional: theme include documented in README (opt-in, not applied). |
| Shell (login shell) | bash rc from $OMARCHY_PATH | zsh w/ starship, plugins | Fundamental difference | **KEEP** zsh entirely. Integration rides the EXISTING `.zshrc` glob over `~/.config/zshrc.d/*.zsh` — zero edits to .zshrc/.zshenv. Omarchy bash layer simply unused (vendored for completeness). |
| Prompt | n/a (bash) | starship rose_pine_moon | none | **KEEP** untouched. |
| Env vars | OMARCHY_PATH via uwsm env.d | none | none | **MERGE**: `/etc/environment.d/10-de-omarchy.conf` + zsh hook export + Hyprland `hl.env`. Fallback hardcoded in layer bootstrap too. |
| Keybindings | full default bind set | keymap.lua single source of truth | 13 direct conflicts (see KEYMAP.md) | All conflicts → USER wins. Non-conflicting Omarchy binds added via curated `deo-bindings.lua` (never touches keymap.lua). |
| Display/monitors | example monitors module | live 3-monitor layout incl. rotated DP-4 @100Hz | none (host owns it) | **KEEP** host layout untouched; real layout recorded in display/monitors.lua for reference/restore. |
| GTK/Qt/cursor theme | theme-set commands update gnome settings + cursor | Bibata-Material-Rose-Pine cursors, gtk configs present | partial | ADOPT for new themes via omarchy-theme-set (it sets gtk/cursor consistently); initial rose-pine apply included. User's originals remain in backups. |
| Wallpapers | per-theme backgrounds managed by shell | wallpaper.sh (swww-based picker) | Two sources possible | ADOPT Omarchy backgrounds through theme system; user's picker script still works if invoked manually. swww daemon left running harmlessly. |
| Fonts | JetBrains Mono Nerd basic pack | JetBrains Mono Nerd Font already installed | none | MERGE: ensure nerd-font package present; user font choice unchanged. |
| Package base | ~150 packages incl. kernels/drivers/docker | CachyOS system layer | Distro-hostile items | Only curated UI list installed (packages/ui.packages); pacman.conf/kernel/bootloader never touched. |

## Conflict register requiring user awareness

| Keys | Omarchy action | Your binding (KEPT) |
|---|---|---|
| SUPER+SPACE | Omarchy menu (→ moved to SUPER+SHIFT+M) | Toggle floating |
| SUPER+W | Close window | Wallpaper picker |
| SUPER+T | Toggle float | Theme switcher |
| SUPER+C | Universal copy | VS Code |
| SUPER+V | Universal paste | Clipboard history |
| SUPER+X | Universal cut | Neovim |
| SUPER+L | Workspace layout toggle | Lock screen |
| SUPER+ESCAPE | System menu | Emergency lock |
| CTRL+ALT+DELETE | Close all windows | Power menu |
| SUPER+SHIFT+COMMA | Dismiss all notifications | Player previous |
| SUPER+CTRL+S | Share menu | Region screenshot |
| SUPER+CTRL+R | Set reminder | hyprctl reload |
| XF86 media/brightness | omarchy-* equivalents | Your scripts (identical actions) |

Nothing above was silently dropped: every Omarchy action that lost its default
key remains reachable via its menu or an alternate free combo listed in KEYMAP.md.
