# PARITY AUDIT — de-omarchy vs upstream Omarchy

Audited 2026-08-23 against `/home/swadhin/omarchy` (upstream checkout).
Method: full recursive diffs of every tree (`bin/`, `shell/`, `config/`,
`default/`, `themes/`, `applications/`), plus top-level structure comparison
and spot verification of behavioral claims. Every "missing" below was
verified against actual file presence and cross-references from surviving
code, not assumed from docs.

## RESOLUTION LOG (2026-08-23, later same day)

Scope confirmed: UI/shell/theme/application layer only — no ISO/distro
machinery. Resolved per §8 action order:

- ✅ §3.1 Ported `default/chromium/` (extensions + native-messaging-hosts) — unbreaks both installers
- ✅ §4.1 Ported `default/agents/skills/` (paths rewritten to de-omarchy); fork's provision-user loop + new install.sh wiring activate them
- ✅ §4.2 Ported `default/xcompose`; install.sh writes `~/.XCompose` including it (never overwrites)
- ✅ §4.3 Ported `default/voxtype/config.toml`; install.sh deploys it when absent
- ✅ §4.4 Ported `default/tensaku/state.toml`
- ✅ §4.5 Ported screensaver configs for foot/alacritty (+ Alacritty.desktop) and ghostty
- ✅ §4.6 Ported `default/audio/filter-chain-host.conf` + `tunings/`
- ✅ §4.9 Ported `default/xdg-terminal-exec/hyprland-xdg-terminals.list`
- ✅ §6 Vendored `docs/` (with `docs/FORK-NOTES.md` deltas), `manual/`, `agents/`; runtime paths rewritten inside
- ⏸️ §4.10 gpg dirmngr — skipped (touches existing ~/.gnupg; low value)
- ⏸️ §4.7 Firefox policies / fontconfig / libalpm guard — system layer, out of scope per confirmed scope
- ⏸️ migrations decision — still open (vendor vs remove runner)
- Deploy of everything above rides on the next `sudo bash install.sh` / runtime sync (same pending sudo as the bar-style + notification work)

## Verdict in one paragraph

The fork tracks upstream unusually closely: all 22 themes, `applications/`,
`shell/services`, `shell/Ui`, all popup panels, and ~411 of 431 shared CLI
commands are byte-identical. `bin/` and `config/` are strict supersets
(fork adds 10 commands, 7 shell plugins). The real gaps concentrate in
`default/` (119 missing paths — mostly distro/installer machinery, but three
user-facing features among them), the eight absent top-level dirs
(`docs/ manual/ migrations/ install/ etc/ test/ agents/ plans/`), and one
**broken-by-reference** case: Chromium extension installers whose asset
files were never copied over.

---

## 1. Confirmed parity (no action needed)

| Area | Evidence |
|---|---|
| Themes | All 22 identical (except `icons.theme` in 8 light-ish themes: Yaru-* → `breeze`, deliberate Dolphin/Papirus change) |
| Applications (.desktop + icons) | Identical |
| Shell core (`shell/services/`, `shell/Ui/`) | Identical file-for-file |
| Popup panels (audio/bluetooth/clock/network/power/tailscale/dropbox/weather/wifiqr/speedtest/disk-speedtest/monitor) | Identical under `shell/plugins/panels/` |
| Plugin lifecycle CLIs | `plugin add/clone/update/remove/enable/disable/list/validate` byte-identical |
| Bar gestures & engine | Identical except deliberate bar-style additions |
| Toggles/hooks/menu/theme-set plumbing | Identical |

## 2. Fork-only additions (not gaps — inventoried for completeness)

- `bin`: `omarchy-plugins` (marketplace via omarchyplugins.com catalog),
  `omarchy-plugin-manager`, `omarchy-plugin-library`, `omarchy-keybindings`,
  `omarchy-monitor-manager`, `omarchy-monitormgr`, `omarchy-bar-style-{list,set,cycle,menu}`
- Shell plugins: `plugin-manager`, `plugin-library`, `notification-center`,
  `power-profile`, `docker-status`, `system-overview`, `wallpaper-manager`
- Config: NvChad nvim config, starship, zshrc.d layer, PAM lock config,
  `deo-layer/bindings/autostart.lua` additive Hyprland layer
- Defaults: `bar.transparent: true`, sysmon widget, notification-center widget

---

## 3. GAPS — broken by reference (fix first)

### 3.1 Chromium extensions & native messaging hosts — `default/chromium/` missing entirely
Upstream ships `default/chromium/{extensions/{copy-url,yt-dlp,whatsapp-slim},native-messaging-hosts/}`.
The fork kept the CLIs but lost the assets they load:

- `bin/omarchy-install-chromium-copy-url:9` → `$OMARCHY_PATH/default/chromium/native-messaging-hosts/$HOST_NAME.json` — **file does not exist at runtime**
- `bin/omarchy-install-chromium-ytdlp:9` → same pattern
- Consequence: "Copy tab URL" (Alt+Shift+L) and "Download video" (Alt+Shift+D)
  integrations cannot be installed. `omarchy-chromium-copy-url-host` /
  `omarchy-chromium-ytdlp-host` (the hosts themselves) DID survive — only the
  registration templates and extension sources are gone.

Fix: copy `default/chromium/` from upstream into the fork (paths already
match; `omarchy-upgrade-to-quattro` even references the expected runtime
path `/usr/share/de-omarchy/default/chromium/extensions/copy-url`).

## 4. GAPS — user-facing features upstream has, fork lacks

Ordered by how much a daily user would notice.

| # | Feature | Upstream location | Notes |
|---|---|---|---|
| 4.1 | **AI agent skill bundling** | `default/agents/skills/omarchy/` (SKILL.md + capture/contributing/hooks/hyprland/plugins/theming md) and `skills/diagnose-crash/` | Manual ch 17: skills are symlinked into Claude Code/Codex/etc. skill dirs so agents can drive Omarchy natively and diagnose crashes. Fork has `omarchy-agent*` usage CLIs but no bundled skills. High leverage, cheap to port. |
| 4.2 | **CapsLock compose: emoji sequences & completions** | `default/xcompose/` (+ `~/.XCompose`, `omarchy-restart-xcompose` exists in fork) | Manual ch 34: `CapsLock M <letter>` emoji insertion. Fork has the restart command and fcitx5 mentions in bindings but no default XCompose payload. |
| 4.3 | **Dictation (Voxtype) config** | `default/voxtype/config.toml` | Fork has the whole `omarchy-voxtype-*` command family but no shipped config; first-run experience depends on it. |
| 4.4 | **Screenshot annotation state** | `default/tensaku/state.toml` | Annotation editor (manual ch 12). Check whether tensaku itself is in packages/ui.packages before porting. |
| 4.5 | **Screensaver terminal configs** | `default/{foot/screensaver.ini, alacritty/screensaver.toml, ghostty/screensaver}` | The ASCII-logo screensaver renders in the configured terminal; without per-terminal screensaver styling it falls back ugly. Fork user runs kitty — verify kitty path covers them, then decide. |
| 4.6 | **Audio filter chain + per-device tunings** | `default/audio/filter-chain-host.conf`, `audio/tunings/<device>/` | `omarchy-audio-tuning` command exists in fork; its data does not. Affects only tuned devices (e.g. dell-xps-2026 profile present upstream). |
| 4.7 | **Firefox policies** | `default/firefox/policies.json` | Wayland flags/policies if the user switches browsers. Low priority. |
| 4.8 | **fontconfig overrides** | `default/fontconfig/conf.avail/` | Font substitution/aliasing guarantees. Low priority on an existing system that already renders fine. |
| 4.9 | **xdg-terminal-exec mapping** | `default/xdg-terminal-exec/hyprland-xdg-terminals.list` | Terminal autodiscovery for XDG callers. Small but trivial to copy. |
| 4.10 | **GPG dirmngr config** | `default/gpg/dirmngr.conf` | Keyserver hygiene. Trivial. |

Not applicable by design: `nautilus-python/extensions` (fork replaced
Nautilus with Dolphin in commit fc10361).

## 5. GAPS — distro/installer machinery (intentional, documented for completeness)

These exist upstream because Omarchy IS a distro. de-omarchy installs onto an
existing Arch/CachyOS system, so their absence is policy — but each carries a
consequence worth knowing:

| Upstream area | Fork consequence |
|---|---|
| `install/` (ISO, provisioning, hardware drivers) | No assisted install — `install.sh` layers UI only. Accepted scope. |
| `etc/` + `default/pacman/` (mirrors per channel, repo signing, `libalpm/hooks` blocking direct `pacman -Syu`) | Nothing stops a direct pacman full-upgrade from racing omarchy's own update flow. Consider re-adding just the libalpm guard hook. |
| `default/limine/` + `snapper/` | No automatic pre-update snapshots, no boot-into-snapshot rollback (manual ch 30/47). Mitigate via CachyOS's own snapper/grub-btrfs if present. |
| `default/plymouth/` (boot splash + unlock art incl. per-theme unlock designs) | Style > Unlock feature is dead; `omarchy plymouth preview/set` will fail. Also means theme `preview-unlock.png` assets are unused. |
| `default/sddm/` | SDDM stays unthemed (system-level; install.sh explicitly doesn't touch it). Accepted. |
| `default/systemd/{zram-generator.conf.d, faster-shutdown.conf, user@.service.d}` | No zram/shutdown tuning. Usually already sensible on CachyOS. |
| `udev/framework16-qmk-hid.rules` | Only matters on Framework 16 keyboards. |
| `default/bashrc`, bash env stack | Replaced by zsh (`config/zshrc.d/50-de-omarchy.zsh`). Intentional. |

## 6. GAPS — developer experience & update safety

| Missing dir | Impact |
|---|---|
| `docs/` | The 9 internal docs (omarchy-shell, theming, cli-router, file-layout, menu, notifications, audio-tuning, testing, update-process). We read them from the upstream clone; consider vendoring with fork-specific amendments so they stop drifting. |
| `manual/` | The 51-chapter user manual shown by the About/help flows upstream. Fork users have KEYMAP.md only. |
| `test/` | `test/cli` + `test/shell` regression suites (upstream runs `commands --check` inside them). Fork currently relies on ad-hoc checks — we ran `omarchy commands --check` manually today. |
| `migrations/` | **Subtle risk:** fork keeps `bin/omarchy-migrate` but deleted the migration scripts directory, so updates run zero migrations. Any future layout change (like upstream's shell.json v1 migration) must be handled manually. Either vendor the dir or delete the runner to avoid a silent no-op. |
| `agents/` | Agent-facing command metadata guide referenced by cli-router.md. Docs-only. |
| `plans/` | Design notes. Docs-only. |

## 7. Deliberate divergences in shared files (audit trail)

20 bin scripts differ; all trace to the port or to fork features:

- **Distro machinery rewritten**: `omarchy`, `apply-hardware`, `apply-system`,
  `channel-current/set`, `migrate`, `provision-owner/user`,
  `system-factory-reset`, `theme-set-gnome`, `update-available`,
  `update-dev`, `update-system-pkgs`, `upgrade-to-quattro`, `version`,
  `version-branch`, `dev-status`, `dev-unlink`
- **Fork features**: `plugin-add`, `plugin-remove` (registry.json integration)
- **QML**: `shell.qml` (+46 lines), `Bar.qml` (style presets/islands),
  `notifications/Service.qml` (focused-monitor + finite expiries)
- **Hyprland Lua**: `bootstrap.lua` (reload_prefixes), `windows.lua`,
  `paths.lua`; `uwsm/env.d/10-omarchy`; `bash/env*` (zsh); `kitty/kitty.conf`;
  `config/omarchy/shell.json` defaults

## 8. Recommended action order

1. Port `default/chromium/` (unbreaks two shipped commands) — minutes.
2. Vendor `docs/` + `manual/` (with a fork README noting deltas) — hours, stops doc drift.
3. Port `default/agents/skills/` and wire the symlink step into install.sh — high value for this user's AI-heavy workflow.
4. Decide migrations policy (vendor or remove runner) before the next big change.
5. Add the libalpm pacman-guard hook adapted for CachyOS.
6. Port xcompose + voxtype + tensaku + xdg-terminal-exec payloads (small files, complete features).
7. Screensaver/audio-tuning/fontconfig/firefox — opportunistic.
