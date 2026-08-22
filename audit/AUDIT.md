# AUDIT — current system before de-omarchy

Audited live on the source machine (CachyOS). Full unredacted copies of every
audited file are in the local backup; this document contains no secrets.

## 1. Desktop stack

- **Compositor**: Hyprland 0.56.2 (native **Lua** config API — `hyprland.lua` entry point, `hl.*` / `o.*` bindings).
- **Desktop shell**: custom ecosystem called **"Moonrice"**:
  - Entry: `~/.config/hypr/hyprland.lua` → modules in `~/.config/hypr/hyprland/*.lua`
    (`variables, colors, env, general, gestures, execs, rules, keybinds, monitors`)
  - Shell binary: `~/.local/bin/moonshell` → `qs -c moonshell` (Quickshell config at
    `~/.config/quickshell/moonshell/`), fallback to waybar+swaync when absent
  - User overrides: `~/.config/moonrice/hypr-vars.lua`, display layout in
    `~/.config/moonshell/displays.lua`
- **Idle/lock**: `hypridle` + `hyprlock` (own configs at `~/.config/hypr/hypridle.conf`,
  `hyprlock.conf`); shell's native lock disabled by the user (crashes on this stack).
- **Display manager**: SDDM (system-level; NOT modified by de-omarchy).
- **Other present but unused**: waybar, swaync, wlogout, fuzzel, rofi configs.

## 2. Keybinding map (complete, from keymap.lua)

`~/.config/hypr/keymap.lua` is the single source of truth; consumed by
`keybinds.lua` and a rofi cheat-sheet generator. Categories:

### Shell panels
| Keys | Action |
|---|---|
| SUPER (tap) | Launcher (moonshell) |
| SUPER+M / SUPER+D | Launcher alias |
| SUPER+SHIFT+S | Session menu |
| SUPER+SHIFT+D | Dashboard |
| SUPER+SHIFT+B | Sidebar (network/bluetooth) |
| SUPER+U | Utilities quick toggles |
| SUPER+I | Nexus settings |
| SUPER+SHIFT+K | Show all panels |

### Apps
| Keys | Action |
|---|---|
| SUPER+RETURN | Terminal (kitty) |
| SUPER+ALT+RETURN | Scratchpad terminal |
| SUPER+E | Yazi file manager |
| SUPER+B | Browser (chrome→zen→firefox fallback) |
| SUPER+X | Neovim |
| SUPER+C | VS Code |
| SUPER+ALT+G | Lazygit |
| SUPER+ALT+X | Glow markdown |
| SUPER+ALT+M | Cmus |

### Menus & utilities
| Keys | Action |
|---|---|
| SUPER+A | Actions menu |
| SUPER+SHIFT+A | Mic mute toggle |
| SUPER+V | Clipboard history (cliphist) |
| SUPER+W / SHIFT+W | Wallpaper picker / random |
| SUPER+ALT+C | Rofi calculator |
| SUPER+ALT+W | Rofi window switcher |
| SUPER+H | Keybinding cheat sheet |
| SUPER+T | Theme switcher script |
| SUPER+CTRL+R | hyprctl reload |
| SUPER+SHIFT+C | hyprpicker color picker |

### Window management
| Keys | Action |
|---|---|
| SUPER+Q | Close window |
| SUPER+SPACE / SHIFT+SPACE | Toggle float / center |
| SUPER+F / SHIFT+F | Fullscreen / maximized |
| SUPER+SHIFT+ALT+Q | hyprctl kill |
| SUPER+arrows | Focus direction (repeat) |
| SUPER+SHIFT+arrows | Move window direction |
| SUPER+ALT+Left/Right | Move window across monitors |
| SUPER+mouse272/273 | Drag / resize |

### Workspaces
SUPER+1..0 focus · SUPER+SHIFT+1..0 move

### Lock & power
| Keys | Action |
|---|---|
| SUPER+L | Lock (lock.sh → hyprlock) |
| SUPER+ESCAPE | Lock emergency |
| SUPER+SHIFT+L | Suspend |
| SUPER+ALT+DELETE / CTRL+ALT+DELETE | Power menu |

### Screenshots / media / hardware
F6 full shot · SUPER+CTRL+S region shot · XF86Audio* via user scripts ·
XF86MonBrightness* via scripts · XF86KbdBrightness* brightnessctl ·
SUPER+SHIFT+P/N/COMMA playerctl · CTRL+SUPER+SHIFT+R kill shell ·
CTRL+SUPER+ALT+R restart shell

## 3. Display configuration

See audit/system-fingerprint.md table. Live values match the defaults inside
`hyprland.lua`; per-session overrides possible via `~/.config/moonshell/displays.lua`.

## 4. Zsh configuration

- `~/.zshenv`: sources cargo env + Jan local LLM env (**contains a token — never enters any repo; backed up only**)
- `~/.zshrc`: history opts, LANG/EDITOR/VISUAL/PAGER/GPG_TTY/NODE_OPTIONS/ORACLE exports,
  PATH additions (~/.local/bin, uv, go, bun, opencode), nvm load, secrets.env source,
  compinit, vivid LS_COLORS, lsf/eza ls aliases, TUI aliases (v/fm/top/lg/gl/mu/pa/net/bt/calc/clip),
  fzf bindings+completion, zoxide, starship init, zsh-autosuggestions,
  zsh-syntax-highlighting + Rosé Pine Moon highlight styles, bun completions,
  sources `$HOME/.config/zshrc.d/*.zsh` ← **integration hook used by de-omarchy**
- `~/.config/zshrc.d/`: moonrice.zsh (mr* aliases), dots-hyprland.zsh (quickshell terminal sequences),
  shortcuts.zsh (bindkeys), auto-Hypr.sh
- `~/.zshrc.d/99-flyctl.zsh`: flyctl PATH (legacy location, still kept)
- Prompt: **starship** with a large custom multi-palette config (active: rose_pine_moon)

## 5. Terminal emulator

kitty 0.48: JetBrains Mono Nerd Font 11pt, beam cursor w/ trail, opacity 0.8,
zsh shell, custom copy/search/zoom maps, Rosé Pine Moon palette. Untouched.

## 6. External keybind sources (checked for silent conflicts)

- No GNOME/KDE settings daemon running against Hyprland session.
- xdg-desktop-portal-hyprland active (screen sharing only, no binds).
- systemd/udev: no media-key overrides found outside Hyprland.
- SDDM: no in-session binds.

## 7. Custom scripts the user relies on

`~/.config/hypr/scripts/`: screenshot.sh (grim+slurp), clipboard.sh, wallpaper.sh,
volume.sh, brightness.sh, lock.sh, powermenu.sh, dashboard.sh, weather.sh,
toasts.sh, keyhints.sh, launcher-actions.sh, toggle_floaterm.sh.
Plugins: battery-warn.sh (# AUTOSTART), temp.sh (# AUTOSTART), floating-utils.lua.
All remain installed and functional after de-omarchy (their binds stay live).
