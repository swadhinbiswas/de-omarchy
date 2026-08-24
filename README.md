<h1 align="center">de&#8209;omarchy</h1>

<p align="center">
  <strong>The Omarchy desktop, layered onto any Arch-based system.</strong><br>
  <sub>Hyprland + Quickshell shell, themes, plugins and ~440 CLI commands — installed additively over the Linux you already run.</sub>
</p>

<p align="center">
  <a href="https://github.com/swadhinbiswas/de-omarchy/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-cba6f7?style=flat-square" alt="MIT license" /></a>
  <a href="#installation"><img src="https://img.shields.io/badge/Arch%C2%B7based-Arch%20%7C%20CachyOS%20%7C%20EndeavourOS%20%7C%20Manjaro-1793D1?style=flat-square&amp;logo=archlinux&amp;logoColor=white" alt="Arch-based" /></a>
  <a href="https://github.com/basecamp/omarchy"><img src="https://img.shields.io/badge/port%20of-Omarchy-4550e0?style=flat-square&amp;logo=github&amp;logoColor=white" alt="Port of Omarchy" /></a>
  <a href="https://github.com/swadhinbiswas/de-omarchy/issues"><img src="https://img.shields.io/github/issues/swadhinbiswas/de-omarchy?style=flat-square&amp;color=d29922" alt="Open issues" /></a>
</p>

<p align="center">
  <img src="https://cdn.simpleicons.org/hyprland/cba6f7" height="26" alt="Hyprland" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/wayland/cba6f7" height="26" alt="Wayland" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/archlinux/cba6f7" height="26" alt="Arch Linux" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/lua/cba6f7" height="26" alt="Lua" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/zsh/cba6f7" height="26" alt="zsh" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/neovim/cba6f7" height="26" alt="Neovim" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/starship/cba6f7" height="26" alt="Starship" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/docker/cba6f7" height="26" alt="Docker" />&nbsp;&nbsp;
  <img src="https://cdn.simpleicons.org/git/cba6f7" height="26" alt="Git" />
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/Install%20in%20minutes-2ea44f?style=for-the-badge" alt="Install" /></a>&ensp;
  <a href="https://discord.gg/4fZ8fawe6"><img src="https://img.shields.io/badge/Join%20the%20Discord-5865F2?style=for-the-badge&amp;logo=discord&amp;logoColor=white" alt="Discord" /></a>&ensp;
  <a href="manual/01-welcome-to-omarchy.md"><img src="https://img.shields.io/badge/Read%20the%20Manual-24292f?style=for-the-badge" alt="Manual" /></a>
</p>

---

de-omarchy takes the [Omarchy](https://github.com/basecamp/omarchy) experience — the bar, launcher, theming, notifications, lock screen, screensaver — and installs it as a **self-contained desktop layer** on top of your existing system. No ISO, no bootloader, no display manager, no mirrors touched. Everything it adds is additive, marked, and reversible.

Your system stays yours. Your bindings win. Uninstalling puts everything back exactly as it was.

## At a glance

| | |
|---|---|
| **Quickshell desktop** | Bar, launcher, menus, notifications, clipboard, emojis, lock screen, OSD |
| **10 bar styles** | Classic → Floating Islands → Glass → OLED Black… cycle live with <kbd>SUPER</kbd>+<kbd>CTRL</kbd>+<kbd>Y</kbd> |
| **22 themes** | One TOML file each; live switching across terminal, GTK, and shell |
| **System monitor widget** | CPU, RAM, disk, GPU temp, network — sampled every 2 s, click opens btop |
| **Notification center** | History panel + do-not-disturb, <kbd>SUPER</kbd>+<kbd>ALT</kbd>+<kbd>N</kbd> |
| **Plugin marketplace** | Browse and install community plugins (<kbd>SUPER</kbd>+<kbd>SHIFT</kbd>+<kbd>I</kbd>) |
| **Monitor Manager** | Visual multi-monitor arrangement, <kbd>SUPER</kbd>+<kbd>CTRL</kbd>+<kbd>M</kbd> |
| **Animated screensaver** | Terminal-text-effects at 120 fps — the real upstream behavior |
| **~440 CLI commands** | One `omarchy` entry point; every command self-documents for humans *and* AI agents |

## Installation

```bash
git clone https://github.com/swadhinbiswas/de-omarchy.git ~/de-omarchy
cd ~/de-omarchy

./scripts/diff-preview.sh    # dry run — see exactly what would change
./install.sh                 # targeted backup first, then apply
hyprctl reload               # or log out and back in
```

> [!TIP]
> Already installed and re-running later? The installer preserves your current theme, skips packages you already have, and refreshes the runtime — then tells you to run `omarchy-restart-shell`.

**What the installer does, in order:**

1. **Backs up** every file it could touch (plus `.ssh`, zsh stack, starship) to `~/.de-omarchy-backups/<timestamp>/`
2. Installs **missing UI packages only** — never upgrades what you have
3. Deploys the runtime to **`/usr/share/de-omarchy`**
4. Installs four **additive hooks** — symlinks into `~/.config/hypr/` and `~/.config/zshrc.d/`, pointing at *runtime copies*, never at your git checkout
5. Appends **one clearly-marked block** to `hyprland.lua` (pre-change copy saved beside it)
6. Initializes state and applies a default theme on first install only

Idempotent. Safe to re-run any time.

> [!IMPORTANT]
> **The safety contract**
>
> **Never touched:** `pacman.conf`, mirrors, repos, kernel, bootloader, display manager, monitors layout, `.zshrc`, `.zshenv`, `starship.toml`, `kitty.conf`, SSH keys. Nothing in `$HOME` is deleted or overwritten.
>
> **Added:** the runtime dir, the four symlinks, the marked Hyprland block, `/etc/environment.d/10-de-omarchy.conf`, a PAM stanza for the lock screen, and `/usr/bin` symlinks for a dozen commands.

To undo completely:

```bash
./uninstall.sh    # then restore anything else from ~/.de-omarchy-backups/<timestamp>/
```

## Keybindings

Your existing bindings win — de-omarchy only claims keys that are free.

| Key | Action |
|---|---|
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>M</kbd> | Omarchy menu |
| <kbd>SUPER</kbd> + <kbd>K</kbd> | Keybindings cheat sheet window |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Y</kbd> | Cycle bar style |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>N</kbd> | Notification center |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>M</kbd> | Monitor Manager |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>I</kbd> | Plugin Library |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>A</kbd>/<kbd>B</kbd>/<kbd>W</kbd> | Audio / Bluetooth / Network panel |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>SPACE</kbd> | Background switcher |
| <kbd>SUPER</kbd> + <kbd>PRINT</kbd> / <kbd>ALT</kbd> + <kbd>PRINT</kbd> | Screenshot / screen recording |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>T</kbd> | Activity (btop) |
| <kbd>SUPER</kbd> + <kbd>`</kbd> | Scratchpad |

<sub>The full map — including preserved host bindings and every conflict decision — lives in [`keybindings/KEYMAP.md`](keybindings/KEYMAP.md).</sub>

## The CLI

One router, ~440 self-documenting commands. Every command carries machine-readable metadata (`# omarchy:summary=…`), so `--help`, menus, and AI agents all read the same source of truth.

```console
$ omarchy --help                  # grouped, searchable command index
$ omarchy theme list              # 22 themes
$ omarchy theme set catppuccin    # live switch
$ omarchy bar style list          # the 10 bar presets
$ omarchy bar style set glass     # repaint the bar
$ omarchy plugins marketplace     # browse the community catalog
$ omarchy plugins install <name>  # install a plugin headlessly
$ omarchy shell toggle omarchy.audio   # IPC into the running shell
```

## Plugins

Plugins are Quickshell components with a `manifest.json`; kinds are `bar-widget`, `panel`, or `service`. First-party plugins ship inside the runtime and load automatically. User-installed ones live in `~/.config/omarchy/plugins/` and merge in at scan time — anything under the reserved `omarchy.*` namespace always resolves to the first-party version.

Open **Plugin Library** (<kbd>SUPER</kbd>+<kbd>SHIFT</kbd>+<kbd>I</kbd>) for a GUI over the bundled catalog plus the [omarchyplugins.com](https://omarchyplugins.com) marketplace.

## Themes

Each theme is one file — `themes/<name>/colors.toml`. Templates consume its variables and render into your terminal, GTK, and shell configs at switch time. Making a theme is making one TOML file:

```bash
cp -r themes/rose-pine themes/my-theme && $EDITOR themes/my-theme/colors.toml
omarchy theme set my-theme
```

## Screensaver

The real Omarchy screensaver: your branding art rendered by [terminal-text-effects](https://github.com/ChrisBuilds/terminaltexteffects) at 120 fps, a random effect each idle, cursor hidden, exits on any input. Provided by `python-terminaltexteffects` (AUR) — installed automatically; without it the screensaver degrades gracefully to static art rather than failing.

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
- **Runtime** (`OMARCHY_PATH`) — the authoritative copy every process reads: Hyprland Lua modules, the Quickshell shell, all `omarchy-*` commands, plugin manifests.
- **Live config** — `~/.config/hypr/deo-*.lua` are *override slots*: plain symlinks you may replace with your own files. Modules resolve `~/.local/state/` → `~/.config/` → `$OMARCHY_PATH/`, so user state beats fork defaults beats nothing.

Because the runtime is authoritative, deleting or breaking the source checkout cannot hurt a running desktop.

### Development loop

| You changed | Deploy | Apply |
|---|---|---|
| a `bin/omarchy-*` script | `sudo cp bin/omarchy-x /usr/share/de-omarchy/bin/` | nothing needed |
| Hyprland Lua (`default/hypr/`, `config/hypr/`) | same pattern into the runtime | `hyprctl reload` |
| QML under `shell/` | same pattern | `omarchy-restart-shell` |
| a user dotfile template | `omarchy-refresh-config <relpath>` | immediate |

To try unreleased UI without touching the installation, run it straight from the checkout — e.g. `quickshell -p ~/de-omarchy/plugin-library`.

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
├── docs/ manual/ agents/        vendored references (51-chapter manual included)
└── audit/PARITY-AUDIT.md        fork-vs-upstream audit trail
```

## Documentation

The full [Omarchy Manual](manual/) ships vendored — 51 chapters covering navigation, theming, plugins, updates, troubleshooting, and more. Start at [`manual/01-welcome-to-omarchy.md`](manual/01-welcome-to-omarchy.md). Fork-specific deltas live in [`docs/FORK-NOTES.md`](docs/FORK-NOTES.md); where the two disagree, FORK-NOTES wins.

## Community

Questions, screenshots, theme shares, and help live on the **[de-omarchy Discord](https://discord.gg/4fZ8fawe6)** — usually faster than an issue for "how do I…" questions. Bug reports and feature requests belong on the [issue tracker](https://github.com/swadhinbiswas/de-omarchy/issues); templates are provided for bugs, installation problems, and features. Anything that reproduces in upstream Omarchy itself should go [upstream](https://github.com/basecamp/omarchy) instead.

Before committing, run `scripts/scan-secrets.sh` — it's wired up as a pre-commit hook and blocks secrets or personal paths from entering history.

---

<p align="center">
  <a href="https://discord.gg/4fZ8fawe6"><img src="https://cdn.simpleicons.org/discord/5865F2" height="22" alt="Discord" /></a>&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/swadhinbiswas/de-omarchy/issues"><img src="https://cdn.simpleicons.org/github/e6edf3" height="22" alt="GitHub issues" /></a>&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/basecamp/omarchy"><img src="https://cdn.simpleicons.org/archlinux/cba6f7" height="22" alt="Upstream Omarchy" /></a>
</p>

<p align="center">
  <sub>[Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson and contributors, MIT.<br>
  de-omarchy ports its UI, shell, and tooling for non-Omarchy Arch systems.<br>
  Vendored components retain the upstream license — see <a href="LICENSE.upstream">LICENSE.upstream</a>.</sub>
</p>
