# de-omarchy

**The Omarchy desktop look & workflow for any Arch-based Linux — without
replacing your system.**

de-omarchy takes the UI layer of [Omarchy](https://github.com/basecamp/omarchy)
(Hyprland Lua config, Quickshell desktop shell, 22 themes, `omarchy` CLI,
capture/theming tooling) and installs it **on top of an existing setup**
(CachyOS, Arch, EndeavourOS, Manjaro…) additively and reversibly:

- your `.zshrc`, `.zshenv`, starship prompt, kitty config and ssh keys are
  never modified — the zsh integration rides a glob your `.zshrc` already has
  (`~/.config/zshrc.d/*.zsh`)
- every keybinding you already have stays bound; Omarchy's bindings are added
  only where they were free (full old-vs-new table:
  [`keybindings/KEYMAP.md`](keybindings/KEYMAP.md))
- one marked block is appended to your Hyprland entry file; delete it to revert
- nothing touches pacman.conf, mirrors, kernels, bootloaders or display manager

## Install

```bash
git clone <this-repo> ~/de-omarchy
cd ~/de-omarchy
./scripts/diff-preview.sh     # see exactly what would change (dry run)
./install.sh                  # backs up first, then applies
```

Then either `hyprctl reload` (instant) or re-login for env vars everywhere.

## Uninstall / rollback

```bash
./uninstall.sh                # removes block, symlinks, runtime; restores state
```

Timestamped full backups land in `~/.de-omarchy-backups/<ts>/`
(override with `DEO_BACKUP_ROOT`, e.g. an external drive).

## What you get

| Piece | Detail |
|---|---|
| Shell | Omarchy Quickshell top bar, menu, launcher, notifications, clipboard, emojis |
| Theming | `omarchy theme list` / `omarchy theme set "Tokyo Night"` — kitty/btop/gtk/hypr colors follow |
| CLI | the `omarchy` command router (`omarchy --help`) |
| Capture | PRINT screenshot, ALT+PRINT recording, OCR extraction |
| Extras | scratchpad, window width memory, nightlight, idle toggles |

Default theme after install: `rose-pine`. Change any time.

## Key differences from stock Omarchy

1. **No OS layer**: no bootloader, kernel, plymouth, sddm swap, pacman.conf or
   hardware-specific installers run. Your distro stays yours.
2. **No shell takeover**: Omarchy is bash-first; de-omarchy keeps your login
   shell and prompt exactly as they are.
3. **Merge-not-replace installer**: symlinks + one append block instead of
   copying config trees over `~/.config`.
4. **Conflict policy**: your existing keys always win (see
   [`audit/MAPPING.md`](audit/MAPPING.md)).

## Updating

Pull this repo, re-run `./install.sh` — it is idempotent: runtime rsyncs,
symlinks refresh, the hyprland.lua block is appended only if missing.

## Layout

```
audit/        what was found on the source machine & how conflicts were resolved
bin/          omarchy-* commands (vendored from upstream, MIT)
shell/        Quickshell desktop (vendored)
themes/       22 themes + wallpapers (vendored)
default/      hypr lua runtime, templates, fonts (vendored)
config/       user-side hooks: hypr layer, zsh hook, defaults
packages/     curated UI-only package list
display/      real monitor layout captured from the source machine
keybindings/  KEYMAP.md — complete combined map
scripts/      backup / diff-preview / verify / scan-secrets
```

## Credits & license

Omarchy by David Heinemeier Hansson and contributors, MIT — vendored components
retain that license (`LICENSE.upstream`). Everything de-omarchy adds is MIT too
(`LICENSE`).
