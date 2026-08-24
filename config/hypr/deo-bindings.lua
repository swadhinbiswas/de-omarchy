-- De-omarchy keybindings: non-conflicting Omarchy defaults redefined here.

-- Tiling / Window management
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
o.bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")

-- Workspaces
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))
o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + grave", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + grave", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Monitor move
o.bind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
o.bind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

-- Window cycling
o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))

-- Resize (code:20 / code:21 family)
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

-- Mouse
o.bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Menus
o.bind("SUPER + SHIFT + M", "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + CTRL + E", "Emojis", "omarchy-shell shell toggle omarchy.emojis")
o.bind("SUPER + K", "Keybindings", "omarchy-keybindings")
o.bind("SUPER + CTRL + Q", "Calculator", "omacalc")
o.bind("XF86Calculator", "Calculator", "omacalc")
o.bind("XF86PowerOff", "Power menu", "omarchy-menu toggle system", { locked = true })

-- Bar panels
o.bind("SUPER + CTRL + SPACE", "Background switcher", "omarchy-menu toggle background")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu toggle theme")
o.bind("SUPER + CTRL + A", "Audio", "omarchy-shell shell toggle omarchy.audio")
o.bind("SUPER + CTRL + B", "Bluetooth", "omarchy-shell shell toggle omarchy.bluetooth")
o.bind("SUPER + CTRL + W", "Network", "omarchy-shell shell toggle omarchy.network")
o.bind("SUPER + CTRL + Y", "Cycle bar style", "omarchy-bar-style-cycle")

-- Notifications
o.bind("SUPER + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + ALT + comma", "Invoke last notification", "omarchy-shell notifications invokeLast")
o.bind("SUPER + SHIFT + ALT + comma", "Open notification history", "omarchy-shell notifications showHistory")
o.bind("SUPER + ALT + N", "Notification center", "omarchy-shell deomarchy.notification-center toggle")
o.bind_toggle("SUPER + CTRL + comma", "Toggle silencing notifications", "notification-silencing")

-- Toggles
o.bind_toggle("SUPER + CTRL + I", "Toggle locking on idle", "idle")
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
o.bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

-- Capture
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")
o.bind("ALT + PRINT", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "omarchy-capture-text")

-- Monitor manager
o.bind("SUPER + CTRL + M", "Monitor Manager", "omarchy-monitor-manager")

-- Shell lifecycle
o.bind("SUPER + CTRL + ALT + S", "Restart Omarchy shell", "omarchy-restart-shell")

-- Laptop
o.bind("SUPER + CTRL + Delete", "Toggle laptop display", "omarchy-hyprland-monitor-internal toggle")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })

-- Zoom
o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Reminders
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "omarchy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "omarchy-reminder clear")

-- System info
o.bind("SUPER + CTRL + ALT + T", "Show time", "omarchy-notification-time")
o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", "omarchy-notification-battery")
o.bind("SUPER + CTRL + ALT + W", "Toggle weather", "omarchy-notification-weather")

-- Agent
o.bind("SUPER + SHIFT + CTRL + A", "Agent", "omarchy-agent --pick")

-- Panels
o.bind("SUPER + CTRL + D", "Display", "omarchy-shell shell toggle omarchy.monitor")
o.bind("SUPER + CTRL + ALT + D", "Calendar", "omarchy-shell shell toggle omarchy.clock")
o.bind("SUPER + CTRL + P", "Power", "omarchy-shell shell toggle omarchy.power")
o.bind("SUPER + CTRL + T", "Activity", { tui = "btop" })
