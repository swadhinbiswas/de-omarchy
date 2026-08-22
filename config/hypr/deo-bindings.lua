-- ============================================================================
--  de-omarchy curated bindings — ALL Omarchy defaults that don't conflict
--
--  Host (Moonrice) keymap stays untouched above this. Every conflicting key
--  is skipped here and documented in audit/MAPPING.md + keybindings/KEYMAP.md.
--
--  Skipped (host owns):
--    SUPER+SPACE (float), SUPER+SHIFT+SPACE (center), SUPER+W (wallpaper),
--    SUPER+T (theme switcher), SUPER+C (code), SUPER+V (clipboard history),
--    SUPER+X (nvim), SUPER+L (lock), SUPER+ESCAPE (emergency lock),
--    CTRL+ALT+DELETE (power), SUPER+F (fullscreen), SUPER+SHIFT+F (maximized),
--    SUPER+SHIFT+arrows (move window), workspace digits 1-0,
--    all XF86 media/brightness (user scripts), SUPER+CTRL+S (region screenshot),
--    SUPER+CTRL+R (hyprctl reload), SUPER+SHIFT+COMMA (playerctl prev),
--    SUPER+ALT+G (lazygit), SUPER+ALT+Left/Right (move to monitor)
-- ============================================================================

----------------------------
---- Window management ----
----------------------------
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
o.bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
o.bind("SUPER + G", "Toggle grouping", hl.dsp.group.toggle())
o.bind("SUPER + ALT + SHIFT + TAB", "Previous in group", hl.dsp.group.prev())
o.bind("SUPER + CTRL + LEFT", "Move group focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + RIGHT", "Move group focus right", hl.dsp.group.next())
o.bind("SUPER + ALT + mouse_down", "Next in group", hl.dsp.group.next())
o.bind("SUPER + ALT + mouse_up", "Previous in group", hl.dsp.group.prev())
for i = 1, 5 do
  o.bind("SUPER + ALT + code:" .. tostring(10 + i), "Switch to group window " .. i, hl.dsp.group.active({ index = i }))
end
o.bind("SUPER + SLASH", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")

----------------------------
---- Workspaces ----
----------------------------
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + grave", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + grave", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

o.bind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
o.bind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

----------------------------
---- Window cycling ----
----------------------------
o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

----------------------------
---- Resize (minus/equals family) ----
----------------------------
o.bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
o.bind("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:21", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))
o.bind("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
o.bind("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

----------------------------
---- Mouse scroll workspaces ----
----------------------------
o.bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

----------------------------
---- Menus & utilities ----
----------------------------
-- SUPER+SPACE (Omarchy upstream) is taken by host (float toggle).
-- Omarchy menu → SUPER+SHIFT+M; apps menu → SUPER+ALT+SPACE.
o.bind("SUPER + SHIFT + M", "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + CTRL + E", "Emojis", "omarchy-shell shell toggle omarchy.emojis")
o.bind("SUPER + CTRL + O", "Toggle menu", "omarchy-menu toggle toggle")
o.bind("SUPER + CTRL + H", "Hardware menu", "omarchy-menu toggle hardware")
o.bind("SUPER + SHIFT + code:201", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + ALT + K", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + CTRL + K", "Herdr keybindings", "omarchy-menu-herdr-keybindings")
o.bind("SUPER + CTRL + Q", "Calculator", "omacalc")
o.bind("XF86Calculator", "Calculator", "omacalc")
o.bind("XF86PowerOff", "Power menu", "omarchy-menu toggle system", { locked = true })

----------------------------
---- Bar panel toggles ----
----------------------------
o.bind("SUPER + CTRL + SPACE", "Background switcher", "omarchy-menu toggle background")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu toggle theme")
o.bind("SUPER + CTRL + A", "Audio panel", "omarchy-shell shell toggle omarchy.audio")
o.bind("SUPER + CTRL + B", "Bluetooth panel", "omarchy-shell shell toggle omarchy.bluetooth")
o.bind("SUPER + CTRL + D", "Display panel", "omarchy-shell shell toggle omarchy.monitor")
o.bind("SUPER + CTRL + ALT + D", "Calendar panel", "omarchy-shell shell toggle omarchy.clock")
o.bind("SUPER + CTRL + W", "Network panel", "omarchy-shell shell toggle omarchy.network")
o.bind("SUPER + CTRL + P", "Power panel", "omarchy-shell shell toggle omarchy.power")
o.bind("SUPER + CTRL + T", "Activity (btop)", "{ tui = \"btop\" }")
for i = 1, 9 do
  o.bind("SUPER + CTRL + code:" .. tostring(10 + i), "Bar panel " .. i, "omarchy-shell -q shell togglePanelAt right " .. i)
end

----------------------------
---- Notifications ----
----------------------------
o.bind("SUPER + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + ALT + comma", "Invoke last notification", "omarchy-shell notifications invokeLast")
o.bind("SUPER + SHIFT + ALT + comma", "Open notification history", "omarchy-shell notifications showHistory")
o.bind_toggle("SUPER + CTRL + comma", "Toggle silencing notifications", "notification-silencing")

----------------------------
---- Toggles ----
----------------------------
o.bind_toggle("SUPER + CTRL + I", "Toggle locking on idle", "idle")
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
o.bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

----------------------------
---- Zoom ----
----------------------------
o.bind("SUPER + CTRL + Z", "Zoom in", "omarchy-hyprland-cursor-zoom in")
o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", "omarchy-hyprland-cursor-zoom reset")

----------------------------
---- Reminders & notifications ----
----------------------------
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "omarchy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "omarchy-reminder clear")
o.bind("SUPER + CTRL + ALT + T", "Show time", "omarchy-notification-time")
o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", "omarchy-notification-battery")
o.bind("SUPER + CTRL + ALT + W", "Toggle weather", "omarchy-notification-weather")

----------------------------
---- Capture ----
----------------------------
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")
o.bind("ALT + PRINT", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "omarchy-capture-text")
o.bind("SUPER + CTRL + PERIOD", "Transcode", "omarchy-transcode")

----------------------------
---- Agent ----
----------------------------
o.bind("SUPER + SHIFT + CTRL + A", "Agent", "omarchy-agent --pick")

----------------------------
---- Laptop / hardware switches ----
----------------------------
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })
o.bind("SUPER + CTRL + Delete", "Toggle laptop display", "omarchy-hyprland-monitor-internal toggle")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")
