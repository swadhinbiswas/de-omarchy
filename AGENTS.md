# de-omarchy — Project Brief for AI Assistants

Read this file first. It tells you what this project is, how it is shaped, and exactly where to write different kinds of code.

## What this project is

`de-omarchy` is a **pure Arch / CachyOS port of [Omarchy](https://github.com/omarchy/omarchy)** — DHH's opinionated Hyprland desktop config — with every macOS assumption removed and Arch tooling (pacman/AUR, systemd, uwsm) used instead. It is a desktop environment layer, not an application: it configures Hyprland, a Quickshell QML status bar, keybindings, themes, and ~435 small CLI helper commands.

The repo (this checkout, e.g. `~/de-omarchy`) is the **source**. It is deployed (rsync'd) to the runtime at `/usr/share/de-omarchy`. The running desktop reads from the runtime, never from the repo. `OMARCHY_PATH` (set in `/etc/environment.d/10-de-omarchy.conf`) always points at the runtime dir.

## Architecture in one breath

- **Hyprland** (Wayland compositor) configured in Lua: `default/hypr/` is the source tree, merged into `~/.config/hypr/` on deploy/refresh.
- **Quickshell** (a QML Wayland shell) renders the bar, panels, OSD, notifications, lock screen, etc. Source: `shell/`.
- **~435 bash commands** in `bin/`, all prefixed `omarchy-`, routed by `bin/omarchy`. They are the stable CLI surface for scripts, keybinds, and the menu.
- **Themes**: `themes/*/colors.toml` + `default/themed/*.tpl` templates rendered into user config.
- **Plugin system**: first-party shell plugins live in `shell/plugins/`; installable plugins are listed in `registry.json` and surfaced in a Plugin Library window (`plugin-library/`).
- **Keybindings**: `default/hypr/keymap.lua` (Lua table of binds) — the live copy is `~/.config/hypr/keymap.lua`.

## Directory map (where things live)

```
de-omarchy/
  bin/                     # ALL CLI commands (omarchy-*). Router = bin/omarchy
  shell/                   # Quickshell QML desktop
    shell.qml              #   entry point; loads plugins via pluginRegistry
    Commons/  Ui/          #   shared QML imports (use `import qs.Commons`, `import qs.Ui`)
    plugins/               #   first-party plugins, one dir each
      bar/                 #     the main bar + indicators/ widgets (+ BarStyles.js presets)
      panels/              #     popup panels (audio, bluetooth, network, power, ...)
      services/            #     background services (idle, media, nightlight, battery)
      notification-center/ #     bell widget + history panel (SUPER+ALT+N)
      plugin-library/  plugin-manager/  docker-status/  sysmon/  ...  # feature plugins
  plugin-library/          # STANDALONE Plugin Library window (ShellRoot + Window)
    shell.qml              #   launched by `omarchy-plugin-library` (SUPER+SHIFT+I)
  default/                 # system configs copied to runtime (the "defaults")
    hypr/                  #   Hyprland Lua config (keymap.lua, bootstrap.lua, apps/, bindings/)
    themed/                #   theme templates (*.tpl) with {{ variable }} placeholders
    agents/skills/         #   AI agent skills symlinked into ~/.claude, ~/.codex, ...
    chromium/  xcompose  voxtype/  tensaku/  audio/  alacritty/  foot/  ghostty/
    bash/  uwsm/  applications/  systemd/  fonts/
  config/                  # user-dotfile defaults copied to ~/.config (hypr, kitty, git, ...)
  themes/                  # 22 themes, each themes/<name>/colors.toml
  docs/                    # vendored upstream dev docs + FORK-NOTES.md (read deltas first)
  manual/                  # vendored 51-chapter upstream user manual (paths rewritten)
  agents/                  # vendored agent guides (command-metadata.md etc.)
  audit/PARITY-AUDIT.md    # fork-vs-upstream feature audit
  registry.json            # plugin catalog shown in the Plugin Library
  keybindings/KEYMAP.md    # human-readable keybind reference
  install.sh  uninstall.sh # deploy / remove runtime
  packages/  applications/  scripts/  display/  monitor-manager/
```

## Where to write each kind of change

### 1. A new CLI command  →  `bin/omarchy-<group>-<name>`
- Create `bin/omarchy-<group>-<name>`, `#!/bin/bash` shebang, executable bit.
- Add the metadata header block the router parses (`bin/omarchy` scans for these):
  ```bash
  # omarchy:summary=One-line description.
  # omarchy:group=<group>          # optional; inferred from filename prefix otherwise
  # omarchy:args=[--flag] <arg>
  # omarchy:examples=omarchy <group> <name> | omarchy <group> <name> foo
  # omarchy:hidden=true            # optional, hide from listings
  ```
- If `<group>` is new, register it in `GROUP_DESCRIPTIONS` inside `bin/omarchy` so it shows in the top-level help.
- Use bash 5 style: `[[ ]]` for strings/paths, `(( ))` for numbers. Quote string literals in comparisons. Avoid `exec`/`exit` to skip unreachable code; prefer full `if/else`.
- After writing, deploy the single file to the runtime: `sudo cp bin/omarchy-x /usr/share/de-omarchy/bin/` (or re-run `install.sh`).

### 2. A new shell plugin (bar widget / panel / service)  →  `shell/plugins/<name>/`
- Make `shell/plugins/<name>/` with:
  - `manifest.json` — `schemaVersion`, `id` (`deomarchy.<name>`), `name`, `version`, `author`, `kinds` (one of `bar-widget` | `panel` | `service`), `entryPoints`, and a kind-specific block (see `shell/plugins/docker-status/manifest.json` for a `bar-widget`).
  - The QML entry file(s). Use `import qs.Commons` and `import qs.Ui` for shared helpers/colors. Read runtime paths from `Quickshell.env("OMARCHY_PATH")` — never derive from `HOME`.
- `shell/shell.qml` auto-discovers plugins under `plugins/` via `pluginRegistry`; you normally do **not** edit `shell.qml` to add a plugin (only to change core loading).
- Deploy: copy the plugin dir to `/usr/share/de-omarchy/shell/plugins/` and reload the shell (`omarchy-restart-shell` or `hyprctl reload` after the Lua/plugin change).
- A `bar-widget` is placed by the user via the menu; `panel`/`service` kinds start with the shell.

### 3. The standalone Plugin Library window  →  `plugin-library/shell.qml`
- This is a **self-contained** Quickshell app (`ShellRoot` with a `Window` child), launched by the `omarchy-plugin-library` command, bound to **SUPER+SHIFT+I** in `default/hypr/keymap.lua`.
- It is NOT a shell panel and must not `import qs.Commons`/`qs.Ui` (those only resolve inside the main shell). Use literals for colors and `import QtQuick.Controls` for `Button`.
- It reads the catalog with `cat $HOME/.config/omarchy/plugins/registry.json || cat $OMARCHY_PATH/registry.json`. The catalog is `registry.json` at repo root (and deployed to `/usr/share/de-omarchy/registry.json`).
- **Gotcha already hit:** `loadRegistry()` must be invoked from `Component.onCompleted`; a `Process` with `running: true` but no `command` produces empty output and shows "0 plugins".

### 4. A catalog entry for an installable plugin  →  `registry.json`
- Add an object to `plugins[]`: `id`, `name`, `description`, `author`, `category`, `tags`, `kind`, `status`, and `installCommand` (a bash snippet that copies/fetches the plugin into `~/.config/omarchy/plugins/`).
- The Plugin Library's Install button runs `installCommand` via `mkdir -p ~/.config/omarchy/plugins && <installCommand>`.

### 5. A keybinding  →  `default/hypr/keymap.lua`
- Append to the `k` table:
  ```lua
  k[#k + 1] = { cat = "System", keys = "SUPER + SHIFT + I", dsp = exec("omarchy-plugin-library"), desc = "Plugin library" }
  ```
- `dsp` is a Hyprland dispatcher string; use `exec("...")` for shell commands. Do not append raw `hl.bind(...)` calls to `hyprland.lua` (they persist across reloads and stack). Deploy `~/.config/hypr/keymap.lua` via `omarchy-refresh-config hypr/keymap.lua`, then `hyprctl reload`.
- `keymap.lua` is in the Hyprland Lua `reload_prefixes` list (`default/hypr/bootstrap.lua`), so `hyprctl reload` re-reads it. `hyprland.lua` is NOT in that list — editing it requires a full Hyprland restart.

### 6. Theming  →  `themes/<name>/colors.toml` + `default/themed/*.tpl`
- Add a theme dir with `colors.toml` (accent, background, foreground, red…cyan, bright_*). Templates under `default/themed/` consume `{{ variable }}` placeholders.

### 7. User-facing dotfiles  →  `config/<app>/...`
- Copied to `~/.config/<app>` on deploy. Refresh a single one with `omarchy-refresh-config <relpath>` (backs up the existing file first).

## Conventions (follow these exactly)

- Shebangs: `#!/bin/bash` only (never `env bash`).
- Commands & scripts: all start with `omarchy-`. Prefixes hint purpose (`cmd-`, `pkg-`, `hw-`, `refresh-`, `restart-`, `launch-`, `install-`, `setup-`, `toggle-`, `theme-`, `update-`, `capture-`, `plugin-`…).
- In markdown/plans/docs: full lines, two-space indent, no 80-col wrapping.
- `OMARCHY_PATH` is the single source of truth for runtime location. In QML use `Quickshell.env("OMARCHY_PATH")`; in bash `${OMARCHY_PATH:-/usr/share/de-omarchy}`.
- Keep changes atomic and grouped. Don't mix unrelated work in one commit.

## Build / deploy / test loop

1. Edit in the repo (this checkout, e.g. `~/de-omarchy`).
2. Deploy what you changed to the runtime:
   - Full reinstall: `sudo bash install.sh` (rsyncs repo → `/usr/share/de-omarchy`, sets `OMARCHY_PATH`).
   - Single file: `sudo cp <repo/path> /usr/share/de-omarchy/<relpath>`.
3. Apply: `hyprctl reload` for Hyprland/Lua config; `omarchy-restart-shell` (or `hyprctl reload` if the shell is a reload-prefix plugin) for QML; `omarchy-refresh-config <relpath>` for user dotfiles.
4. Verify in the running UI (visual check) plus any CLI sanity check. For QML, watch the Quickshell log at `/run/user/1000/quickshell/by-id/<id>/log.qslog`.

## Gotchas (learned the hard way)

- **Background processes in this shell:** never leave a `quickshell … &` holding the tool's stdout pipe — redirect with `>/dev/null 2>&1 &` and don't put a trailing `&` on the harness command line, or the command appears to hang until timeout. Launch detached via the `omarchy-*` wrapper instead.
- **`keymap.lua` vs `hyprland.lua` reload:** only the prefixes in `default/hypr/bootstrap.lua` `reload_prefixes` are re-evaluated on `hyprctl reload`. Add a new prefix there if you need live reload for it.
- **Standalone QML windows** can't use the main shell's `qs.Commons`/`qs.Ui` imports; inline what they need.
- **Plugin Library "0 plugins":** ensure `loadRegistry()` runs on `Component.onCompleted` and the registry path resolves (`OMARCHY_PATH` set in the session).
- The runtime dir is owned by root; edits there need `sudo`. Never hardcode absolute home paths, hostnames, or credentials anywhere in the repo — `scripts/scan-secrets.sh` runs as a pre-commit hook and blocks commits that contain them.
