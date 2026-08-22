# System Fingerprint — de-omarchy source machine

Scrubbed for public release: no hostname, username, MAC addresses, machine-id,
disk serials, or IP addresses. Full unredacted fingerprint lives only in the
local backup (`~/.de-omarchy-backups/<timestamp>/fingerprint.txt`).

| Field | Value |
|---|---|
| Distro | CachyOS (Arch-based, rolling) |
| Kernel | 6.x x86_64 (CachyOS kernel) |
| Session | Wayland / Hyprland |
| Desktop | Hyprland (custom "Moonrice" Lua config) |
| Display manager | SDDM (untouched by de-omarchy) |
| Shell | zsh (user default) |
| Terminal | kitty (Rosé Pine Moon theme) |
| Compositor version | Hyprland 0.56.2 (Lua config API) |
| Quickshell | quickshell-git 0.3.0 |

## Monitors (from live `hyprctl monitors all`)

| Output | Mode | Position | Scale | Transform | Role |
|---|---|---|---|---|---|
| DP-3 | 1920x1080@60 | 0x0 | 1 | 0 (landscape) | left |
| HDMI-A-3 | 1920x1080@60 | 1920x0 | 1 | 0 (landscape) | middle |
| DP-4 | 1920x1080@100 | 3840x-420 | 1 | 3 (270°) | right, portrait |

## Package baseline at migration time

- Explicitly installed: ~300 packages
- Foreign/AUR: ~42 packages
- Key UI packages already present: hyprland, quickshell-git, hyprlock,
  hypridle, hyprpicker?, grim, slurp, wl-clipboard, cliphist, kitty,
  starship, fuzzel, rofi, waybar, swaync, wlogout, uwsm, sddm, matugen
