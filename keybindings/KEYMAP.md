# KEYMAP — combined bindings after de-omarchy

"Host" = your pre-existing Moonrice keymap (100% preserved).
"de-omarchy" = Omarchy bindings added on top (non-conflicting only).

## Your preserved bindings (host — unchanged)

| Keys | Action |
|---|---|
| SUPER (tap) / SUPER+M / SUPER+D | moonshell launcher* |
| SUPER+SHIFT+S | Session menu |
| SUPER+SHIFT+D | Dashboard |
| SUPER+SHIFT+B | Sidebar |
| SUPER+U | Utilities |
| SUPER+I | Nexus settings |
| SUPER+SHIFT+K | Show all panels |
| SUPER+RETURN | Terminal (kitty) |
| SUPER+ALT+RETURN | Scratchpad terminal |
| SUPER+E | Yazi |
| SUPER+B | Browser |
| SUPER+X | Neovim |
| SUPER+C | VS Code |
| SUPER+ALT+G | Lazygit |
| SUPER+ALT+X | Glow |
| SUPER+ALT+M | Cmus |
| SUPER+A | Actions menu |
| SUPER+SHIFT+A | Mic mute |
| SUPER+V | Clipboard history |
| SUPER+W / SHIFT+W | Wallpaper pick / random |
| SUPER+ALT+C | Rofi calc |
| SUPER+ALT+W | Rofi windows |
| SUPER+H | Key cheat sheet |
| SUPER+T | Theme switcher script |
| SUPER+CTRL+R | hyprctl reload |
| SUPER+SHIFT+C | Color picker |
| SUPER+Q | Close window |
| SUPER+SPACE / SHIFT+SPACE | Float toggle / center |
| SUPER+F / SHIFT+F | Fullscreen / maximized |
| Arrows family | Focus / move / monitor-move |
| SUPER+1..0 / SHIFT+1..0 | Workspace focus / move |
| SUPER+L, SUPER+ESCAPE | Lock screens |
| SUPER+SHIFT+L | Suspend |
| SUPER+ALT+DEL, CTRL+ALT+DEL | Power menu |
| F6, SUPER+CTRL+S | Fullshot, region shot |
| XF86 audio/brightness/kbd | Your scripts |
| SUPER+SHIFT+P/N/COMMA | Playerctl |
| CTRL+SUPER+SHIFT/ALT+R | Kill/restart shell |

\* launcher keys call the moonshell IPC target which the bridge stops at
startup; they become no-ops until you uninstall or re-enable moonshell.
Use SUPER+SHIFT+M (Omarchy menu) instead.

## Added by de-omarchy (Omarchy defaults that were free)

| Keys | Action |
|---|---|
| **SUPER+SHIFT+M** | **Omarchy menu** (upstream: SUPER+SPACE — taken by you) |
| SUPER+ALT+SPACE | Apps menu |
| SUPER+K | Keybindings cheat sheet |
| SUPER+CTRL+E | Emoji picker |
| SUPER+CTRL+Q | Calculator (omacalc) |
| SUPER+CTRL+C | Capture menu |
| SUPER+CTRL+O | Toggles menu |
| SUPER+CTRL+H | Hardware menu |
| SUPER+CTRL+V | Shell clipboard panel |
| SUPER+comma | Dismiss last notification |
| SUPER+ALT+comma | Invoke last notification |
| SUPER+SHIFT+ALT+comma | Notification history |
| SUPER+CTRL+comma | Silence notifications toggle |
| SUPER+CTRL+I | Idle-lock toggle |
| SUPER+CTRL+N | Nightlight toggle |
| PRINT | Screenshot (Omarchy flow) |
| ALT+PRINT | Screen recording |
| SUPER+PRINT | Color picker (hyprpicker) |
| SUPER+CTRL+PRINT | OCR text extraction |
| SUPER+TAB / SHIFT+TAB / CTRL+TAB | Next / prev / former workspace |
| ALT+TAB / ALT+SHIFT+TAB | Cycle windows (+bring to top) |
| CTRL+ALT+TAB (+SHIFT) | Focus next/prev monitor |
| SUPER+S / SUPER+grave | Scratchpad toggle |
| SUPER+ALT+S / SUPER+SHIFT+grave | Move to scratchpad |
| SUPER+J | Toggle split |
| SUPER+P | Pseudo window |
| SUPER+O | Pop window out |
| SUPER+CTRL+F | Tiled fullscreen |
| SUPER+ALT+F | Full width (maximized alt) |
| SUPER+HOME / SUPER+ALT+HOME | Restore/save window width |
| SUPER+minus/equal (+SHIFT/ALT/CTRL variants) | Resize window steps |
| SUPER+mouse wheel | Scroll workspaces |
| SUPER+BACKSPACE / +SHIFT / +CTRL | Transparency / gaps / square toggles |
| Lid switch open/close | Clamshell handling (laptop) |

## Remapped due to conflicts (documented decisions)

| Upstream combo | Taken by you | New home |
|---|---|---|
| SUPER+SPACE (menu) | float toggle | SUPER+SHIFT+M |

## Moonrice launcher keys taken over (dead → live)

These dispatched to the removed moonshell via IPC; install.sh
(scripts/migrate-host-binds.sh) repoints them automatically:

| Keys | Was (dead) | Now |
|---|---|---|
| SUPER tap / SUPER+M / SUPER+D | moonshell:launcher | App drawer (`omarchy-menu toggle apps`) |
| SUPER+SHIFT+S | moonshell:session | Session menu (`omarchy-menu toggle system`) |
| SUPER+U | moonshell:utilities | Quick toggles (`omarchy-menu toggle toggle`) |
| SUPER+W | wallpaper.sh (awww daemon) | Background switcher menu |
| SUPER+SHIFT+W | wallpaper.sh random | Next background (`omarchy-theme-bg-next`) |
| SUPER+T | theme-switcher.sh (dead `moonrice` binary) | Theme menu (`omarchy-menu toggle theme`) |

Commented out with notes (no equivalent yet): SUPER+SHIFT+D dashboard,
SUPER+SHIFT+B sidebar, SUPER+I nexus settings, SUPER+SHIFT+K show-all-panels.

Zero silently-dropped actions: everything else upstream binds either matches a
free key here or is reachable through the Omarchy menu.
