# OMARCHY-INVENTORY — what Omarchy actually is (from the cloned repo)

Enumerated directly from the upstream checkout (v4.0.0.alpha), not from memory.

## Component map

| Layer | Implementation | Location upstream |
|---|---|---|
| Compositor | Hyprland w/ **Lua** config (`hyprland.lua` + `hl.*`/`o.*` API) | `config/hypr/`, `default/hypr/` |
| Desktop shell | **Quickshell** QML app: top bar, launcher, menu, notifications, clipboard, emojis, lock, settings panels | `shell/` (shell.qml, Ui/, plugins/, services/, Commons/) |
| Bar config | JSON-driven widget layout | `config/omarchy/shell.json`, user override `~/.config/omarchy/shell.json` |
| Menu / launcher | In-shell plugin (`omarchy.menu`) driven by IPC (`omarchy-menu`) | `bin/omarchy-menu`, shell plugins |
| Notifications | Shell-native (IPC: dismiss/invoke/history) | shell services |
| Lock/idle | Shell idle service + hyprlock; timers in shell.json (`idle.screensaver/lock`) | shell, `bin/omarchy-apply-lock` |
| Screenshots/OCR/recording | grim/slurp/hyprpicker/tesseract/gpu-screen-recorder behind `omarchy-capture-*` | `bin/` |
| Theming | 22 themes as `colors.toml` + `backgrounds/`; templates rendered to kitty/foot/alacritty/ghostty/btop/neovim/vscode/etc.; state under `~/.local/state/omarchy/current/` | `themes/`, `default/themed/*.tpl`, `bin/omarchy-theme-*` |
| CLI | ~200 `omarchy-*` commands + `omarchy` router with groups & metadata comments | `bin/`, GROUP_DESCRIPTIONS |
| Env model | `$OMARCHY_PATH` (uwsm session env) points at deployed tree `/usr/share/omarchy`; every script/QML resolves through it | `default/uwsm/env.d/10-omarchy` |
| Shell rc | **bash** (not zsh!): `default/bashrc` → sources `$OMARCHY_PATH/default/bash/rc` | `default/bash*` |
| Fonts | JetBrains Mono Nerd (basic), iA Writer, omarchy glyph font | `default/fonts/` |
| Login | SDDM (+ optional uwsm session), Plymouth/Limine for full installs | `install/login/`, `default/sddm/` |

## Installer side effects (what we deliberately do NOT run)

`install/config/all.sh` touches: theme-system, lockout limits, PAM, ssh paths,
docker, snapper, locate db, systemd services, firewall.
`install/user/all.sh`: git identity, chromium policies, xcompose, mise,
hardware fixes (asus/framework/dell/nvidia).
`install/post-install/`: pacman hooks, udev rules, localdb.

**Arch/CachyOS-hostile or out-of-scope pieces**: limine bootloader install,
plymouth, kernel selection (`linux-ptl`), nvidia dkms matrix, pacman.conf
management, ISO provisioning, bash-as-login-shell. de-omarchy extracts only
the UI layer and leaves all of this to the host distro.

## Runtime contract the UI depends on

1. `OMARCHY_PATH` env var pointing at a tree containing `bin/ shell/ themes/
   applications/ default/ config/`.
2. `~/.local/state/omarchy/current/theme.name` + generated theme modules on the
   Lua package.path (written by `omarchy-theme-set`).
3. Hyprland Lua bootstrap adding `$OMARCHY_PATH/?.lua` to package.path — done by
   `default/hypr/bootstrap.lua`, which our layer loads via `dofile`.
4. `quickshell -n -p "$OMARCHY_PATH/shell"` supervised by `bin/omarchy-launch-shell`.

de-omarchy satisfies all four with its own deployment root
(`/usr/share/de-omarchy`) so vendored code runs byte-for-byte unmodified.
