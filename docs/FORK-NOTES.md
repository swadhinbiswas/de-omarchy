# FORK NOTES — how de-omarchy differs from upstream Omarchy

The `docs/`, `manual/`, and `agents/` trees are vendored from upstream
Omarchy so the reference material travels with the fork. They describe
upstream faithfully except for the deltas below. When this file and a
vendored doc disagree, this file wins.

## Paths

| Upstream says | Here |
|---|---|
| `/usr/share/omarchy` | `/usr/share/de-omarchy` (`OMARCHY_PATH`) |
| `github.com/omarchy/omarchy` | this repo (de-omarchy) |
| bash login stack | zsh: `~/.config/zshrc.d/50-de-omarchy.zsh` |

## Not present by design (no ISO — UI/shell/theme/application layer only)

Installer machinery: ISO build, LUKS provisioning, Limine bootloader +
snapshot boot entries, snapper, Plymouth boot splash/unlock art, SDDM theme,
pacman mirrors/repo signing, `libalpm` guard hooks, systemd zram/shutdown
tunings, udev rules, Firefox policies, system fontconfig, wayland-sessions
entry, `etc/skel`.

Consequences: no pre-update snapshot rollback, Style > Unlock is dead,
direct `pacman -Syu` is not blocked.

## Fork additions

- Plugin marketplace: `registry.json` + `omarchy plugins …` CLI + Plugin
  Library/Manager windows (upstream installs plugins from git URLs only)
- Bar style presets: `shell/plugins/bar/BarStyles.js`,
  `omarchy bar style list|set|cycle|menu`, SUPER+CTRL+Y, persisted as
  `bar.styleName` in shell.json
- Extra shell plugins: plugin-manager, plugin-library, notification-center
  (SUPER+ALT+N), power-profile, docker-status, system-overview,
  wallpaper-manager
- Standalone keybindings window: SUPER+K → `omarchy-keybindings`
- Notifications: toasts render only on the Hyprland focused monitor; all
  urgencies expire (3s normal / 6s critical); hover pauses the countdown
- Install model: `install.sh` layers onto an EXISTING Arch/CachyOS system
  additively (backs up first, appends one marked block to hyprland.lua,
  never overwrites user files) instead of owning the machine

## Diverged shared files

See `audit/PARITY-AUDIT.md` §7 for the full audit trail of files that
differ deliberately (update/channel/provisioning rewrites, hypr bootstrap
reload prefixes, kitty config, default shell.json layout).

## Vendoring workflow

To refresh these trees from upstream:

    cp -r /path/to/upstream/{docs,manual,agents} .

…then re-apply nothing — keep deltas in THIS file only, never edit vendored
files in place (except mechanical path rewrites noted here).
