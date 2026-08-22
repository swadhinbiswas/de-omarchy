# de-omarchy

Omarchy's Hyprland desktop UI for any Arch-based distro. Bar, launcher, theming, notifications, lock screen, system monitor — without touching your system layer.

## What it does

- Omarchy Quickshell shell (bar, app drawer, menu, notifications, clipboard, emojis, lock screen, panels)
- 22 themes with live switching (`omarchy theme set <name>`)
- Hyprland look: gaps, borders, animations, window rules matching upstream defaults
- System monitor bar widget (CPU, RAM, disk, GPU temp, network speed)
- `omarchy` CLI (`omarchy --help`, `omarchy theme list`, etc.)
- Full keybinding system with cheat sheet (`SUPER+H`)

## What it does NOT do

- Does not touch pacman.conf, mirrors, kernels, bootloaders, or display manager
- Does not replace your login shell — zsh stays, hook via `~/.config/zshrc.d/*.zsh` glob
- Does not overwrite terminal config, starship prompt, or SSH keys
- Does not install GNOME or Yaru packages
- Adds one marked block to `hyprland.lua` — delete to revert

## Requirements

- Arch-based distro (CachyOS, Arch, EndeavourOS, Manjaro)
- Hyprland 0.56+ with Lua config
- `quickshell` (repo package)
- paru or yay (AUR helper)

## Install

```bash
git clone https://github.com/swadhinbiswas/de-omarchy.git ~/de-omarchy
cd ~/de-omarchy
./scripts/diff-preview.sh   # dry run
./install.sh                 # backs up first, then applies
```

After install: `hyprctl reload` or re-login.

## Uninstall

```bash
./uninstall.sh
```

Restores everything from `~/.de-omarchy-backups/<timestamp>/`.

## Keybindings

| Key | Action |
|---|---|
| `SUPER+M` / `SUPER+D` / `SUPER tap` | App drawer |
| `SUPER+H` | Keybinding cheat sheet |
| `SUPER+T` | Theme switcher |
| `SUPER+SHIFT+M` | Omarchy menu |
| `SUPER+W` | Background switcher |
| `SUPER+E` | Yazi file manager |
| `SUPER+RETURN` | Terminal (kitty) |
| `SUPER+L` | Lock screen |

Existing keybindings preserved. Full map: `keybindings/KEYMAP.md`.

## Architecture

```
de-omarchy/
  install.sh              # idempotent installer
  uninstall.sh            # full rollback
  shell/                  # vendored Quickshell UI
  themes/                 # 22 themes
  bin/                    # omarchy-* commands
  default/                # hypr runtime, templates, fonts
  config/                 # user-side hooks (hypr layer, zsh, PAM)
  scripts/                # backup, verify, migrate, scan-secrets
  packages/               # curated UI-only package list
  audit/                  # system analysis, conflict mapping
```

Runtime: `/usr/share/de-omarchy`. Env: `OMARCHY_PATH` via `/etc/environment.d`, `hl.env`, zsh hook.

## Credits

[Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson (MIT).
Vendored components retain upstream MIT license — see `LICENSE.upstream`.
