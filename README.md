# de-omarchy

**The Omarchy desktop, layered onto any Arch-based system.**

de-omarchy takes the [Omarchy](https://github.com/omarchy/omarchy) Hyprland experience — the Quickshell bar, launcher, theming, notifications, lock screen, screensaver — and installs it as a **self-contained desktop layer** on top of an existing Arch, CachyOS, EndeavourOS, or Manjaro setup. Your system stays yours: no ISO, no bootloader, no display manager, no mirrors touched. Everything de-omarchy adds is additive, marked, and reversible.

Ported from Omarchy by DHH (MIT). See [Credits](#credits).

[Discord](https://discord.gg/4fZ8fawe6) · [Issue tracker](https://github.com/swadhinbiswas/de-omarchy/issues) · [Upstream Omarchy](https://github.com/basecamp/omarchy)

---

## Highlights

| | |
|---|---|
| **Quickshell shell** | Bar, launcher, menus, notifications, clipboard, emojis, lock screen, OSD |
| **10 bar styles** | Classic → Floating Islands → Glass → OLED Black… cycle live with `SUPER + CTRL + Y` |
| **22 themes** | Live switching, `omarchy theme set "Tokyo Night"` |
| **System monitor widget** | CPU, RAM, disk, GPU temp, network throughput — every 2 s, click for btop |
| **Notification center** | Bell widget + history panel, `SUPER + ALT + N` |
| **Plugin marketplace** | Browse and install community plugins from the Plugin Library (`SUPER + SHIFT + I`) |
| **Monitor Manager** | Visual multi-monitor arrangement, `SUPER + CTRL + M` |
| **Animated screensaver** | Terminal-text-effects engine, random effect each idle — exactly upstream |
| **~440 CLI commands** | The full `omarchy-*` surface, routed through one `omarchy` entry point |
| **Agent skills** | Ships Omarchy skills symlinked into Claude Code, Codex, Gemini, and friends |

## Requirements

- An **Arch-based distro** already running **Hyprland configured via Lua** (`hyprland.lua`)
- [`quickshell`](https://quickshell.outfoxxed.me/) — repo package on Arch/CachyOS
- `paru` or `yay` for the handful of AUR-only packages (e.g. `python-terminaltexteffects`, `xdg-terminal-exec`)
- `git`, `rsync`, `curl`

## Install

```bash
git clone https://github.com/swadhinbiswas/de-omarchy.git ~/de-omarchy
cd ~/de-omarchy

./scripts/diff-preview.sh    # dry run — see exactly what would change
./install.sh                 # targeted backup first, then apply
```

Then `hyprctl reload` — or log out and back in so environment variables settle everywhere.

### What the installer does, in order

1. **Backs up** every file it could touch (plus `.ssh`, zsh stack, starship) to `~/.de-omarchy-backups/<timestamp>/`
2. Installs **missing UI packages only** — never upgrades what you have
3. Deploys the runtime to **`/usr/share/de-omarchy`** (`rsync -a --delete` of `bin/ shell/ themes/ default/ config/ …`)
4. Installs **additive hooks**: three symlinks into `~/.config/hypr/`, one into `~/.config/zshrc.d/` — all pointing at *runtime copies*, never at your git checkout
5. Appends **one clearly-marked block** to `~/.config/hypr/hyprland.lua` (pre-change copy saved next to it)
6. Initializes Omarchy state and applies the rose-pine theme

Idempotent: safe to re-run any time.

### The safety contract

**Never touched:** `pacman.conf`, mirrors, repos, kernel, bootloader, display manager, SDDM, monitors layout, `.zshrc`, `.zshenv`, `starship.toml`, `kitty.conf`, SSH keys. Existing configs are merged `--ignore-existing`; nothing in `$HOME` is deleted or overwritten.

**Added:** the runtime dir, the four symlinks above, the marked Hyprland block, `/etc/environment.d/10-de-omarchy.conf` (sets `OMARCHY_PATH`), a PAM stanza for the lock screen, and symlinks for a dozen key commands into `/usr/bin`.

## Uninstall

```bash
./uninstall.sh
```

Strips the marked block, removes the symlinks, deletes the runtime — then restore anything else from `~/.de-omarchy-backups/<timestamp>/`. Your desktop returns to its pre-install state after `hyprctl reload`.

## Keybindings

Your existing bindings win — de-omarchy only claims keys that are free. The essentials:

| Key | Action |
|---|---|
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>M</kbd> | Omarchy menu |
| <kbd>SUPER</kbd> + <kbd>K</kbd> | Keybindings cheat sheet window |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Y</kbd> | Cycle bar style |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>N</kbd> | Notification center |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>M</kbd> | Monitor Manager |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>I</kbd> | Plugin Library |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>A</kbd> / <kbd>B</kbd> / <kbd>W</kbd> | Audio / Bluetooth / Network panel |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>SPACE</kbd> | Background switcher |
| <kbd>SUPER</kbd> + <kbd>PRINT</kbd> / <kbd>ALT</kbd> + <kbd>PRINT</kbd> | Screenshot / screen recording |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>T</kbd> | Activity (btop) |
| <kbd>SUPER</kbd> + <kbd>grave</kbd> | Scratchpad |

Full map, including preserved host bindings and documented conflict decisions: [`keybindings/KEYMAP.md`](keybindings/KEYMAP.md).

## The CLI

One router, ~440 self-documenting commands:

```console
$ omarchy --help                  # grouped, searchable command index
$ omarchy theme list              # 22 themes
$ omarchy theme set catppuccin    # live switch
$ omarchy bar style list          # the 10 bar presets
$ omarchy bar style set glass     # repaint the bar
$ omarchy plugins marketplace     # browse the community catalog
$ omarchy plugin add <git-url>    # sideload a plugin
$ omarchy shell toggle omarchy.audio   # IPC into the running shell
```

Every command carries machine-readable metadata (`# omarchy:summary=…`), so `--help`, menus, and AI agents all read the same source of truth.

## Shell plugins

Plugins are Quickshell components with a `manifest.json`: kinds are `bar-widget`, `panel`, or `service`. First-party plugins ship under `/usr/share/de-omarchy/shell/plugins/` and load automatically; user-installed ones live in `~/.config/omarchy/plugins/` and merge in at scan time (first-party ids — anything under the reserved `omarchy.*` namespace — always win).

Open **Plugin Library** (`SUPER + SHIFT + I`) to browse the bundled catalog plus the [omarchyplugins.com](https://omarchyplugins.com) marketplace, or drive it headless:

```console
$ omarchy plugins list
$ omarchy plugins install docker-status
$ omarchy-shell shell setPluginEnabled deomarchy.power-profile true
```

## Themes

22 themes, each a single `themes/<name>/colors.toml`. Templates under `default/themed/*.tpl` consume `{{ variable }}` placeholders and render into your terminal, GTK, and shell configs at switch time. Making a theme is making one TOML file:

```bash
cp -r themes/rose-pine themes/my-theme && $EDITOR themes/my-theme/colors.toml
omarchy theme set my-theme
```

## Screensaver

The real Omarchy screensaver: your branding art rendered by [terminal-text-effects](https://github.com/ChrisBuilds/terminaltexteffects) at 120 fps, a random effect every idle, cursor hidden, exits on any input. Provided by `python-terminaltexteffects` (AUR) — installed automatically; without it the screensaver degrades gracefully to static art rather than failing.

## Architecture

```
~/de-omarchy (source, yours)         /usr/share/de-omarchy            your session
┌──────────────────────────┐  rsync   ┌──────────────────────┐   symlinks  ┌─────────────────┐
│ bin/      shell/  themes/│ ───────▶ │ OMARCHY_PATH (root)  │ ──────────▶ │ ~/.config/hypr/ │
│ default/  config/ docs/  │          │                      │             │ ~/.config/zshrc.d/
└──────────────────────────┘          └──────────────────────┘             └─────────────────┘
        edit here                     the desktop runs HERE                override slot
```

Three layers, one direction of truth:

- **Source repo** — where you edit. Never referenced at runtime.
- **Runtime** (`OMARCHY_PATH`, set via `/etc/environment.d`) — the authoritative copy every process reads: Hyprland Lua modules, the Quickshell shell, all `omarchy-*` commands, plugin manifests.
- **Live config** — `~/.config/hypr/deo-*.lua` are *override slots*: plain symlinks you may replace with your own files. Hyprland's Lua loader resolves modules in order `~/.local/state/` → `~/.config/` → `$OMARCHY_PATH/`, so user state beats fork defaults beats nothing.

Because the runtime is authoritative, deleting or breaking the source checkout cannot hurt a running desktop.

### Deploy loop for development

| You changed | Deploy | Apply |
|---|---|---|
| a `bin/omarchy-*` script | `sudo cp bin/omarchy-x /usr/share/de-omarchy/bin/` | nothing needed |
| Hyprland Lua (`default/hypr/`, `config/hypr/`) | same pattern into `runtime/<same path>` | `hyprctl reload` |
| QML under `shell/` | same pattern | `omarchy-restart-shell` |
| a user dotfile template | `omarchy-refresh-config <relpath>` | immediate |

To test unreleased UI ad hoc, run it straight from the checkout — e.g. `quickshell -p ~/de-omarchy/plugin-library` — without touching the installation.

## Repository layout

```
de-omarchy/
├── install.sh / uninstall.sh    deploy / fully revert the layer
├── bin/                         ~440 omarchy-* commands; router: bin/omarchy
├── shell/                       Quickshell desktop: Commons/, Ui/, plugins/
│   └── plugins/                 bar/, panels/, services/, notification-center/, …
├── default/                     deployed defaults: hypr/ (Lua), themed/ (tpl), agents/skills/
├── config/                      live-config hooks: hypr/, omarchy/shell.json, pam/, zshrc.d/
├── themes/                      22 × colors.toml
├── registry.json                plugin catalog shown in the Plugin Library
├── monitor-manager/             standalone visual monitor arrangement app
├── plugin-library/              standalone Plugin Library window
├── keybindings/                 KEYMAP.md + cheat-sheet window source
├── docs/ manual/ agents/        vendored upstream references (51-chapter manual included)
└── audit/PARITY-AUDIT.md        fork-vs-upstream audit trail
```

## Documentation

The full [Omarchy Manual](manual/) ships vendored — 51 chapters covering navigation, theming, plugins, updates, troubleshooting, and more. Start at [`manual/01-welcome-to-omarchy.md`](manual/01-welcome-to-omarchy.md). Fork-specific deltas live in [`docs/FORK-NOTES.md`](docs/FORK-NOTES.md); where the two disagree, FORK-NOTES wins.

## Community

Questions, screenshots, theme shares, and help live on the **[de-omarchy Discord](https://discord.gg/4fZ8fawe6)** — it's the fastest way to reach people. Bug reports and feature requests belong on the [issue tracker](https://github.com/swadhinbiswas/de-omarchy/issues); GitHub has templates for bugs, installation problems, and features. Anything that reproduces in upstream Omarchy itself should go to [upstream](https://github.com/basecamp/omarchy) instead.

## Credits

[Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson and contributors (MIT). de-omarchy ports its UI, shell, and tooling for non-Omarchy Arch systems; vendored components retain the upstream license — see `LICENSE.upstream`.
