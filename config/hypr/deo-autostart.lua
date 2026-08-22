-- ============================================================================
--  de-omarchy shell bridge
--
--  Hands the desktop over to the Omarchy Quickshell shell when the layer is
--  active, without editing the host autostart:
--    * stops any previous quickshell instance (moonshell / ii configs)
--    * stops the host's hypridle so Omarchy's shell owns idle/lock timing
--      (host hyprlock config is kept and reused for the lock UI)
--    * dedupes cliphist watchers (host execs already start two)
--  Then loads stock Omarchy autostart (shell supervisor, monitor watch,
--  udiskie, power profiles, post-boot hooks).
--
--  The supervisor is launched BOTH on session start (`hyprland.start`) and
--  immediately, so a plain `hyprctl reload` also brings the shell up — the
--  upstream autostart only hooks `hyprland.start`, which does not fire on
--  reload.
-- ============================================================================

local function kill_old_shell()
  hl.exec_cmd(
    "pkill -f 'quickshell.*-c moonshell' 2>/dev/null"
      .. "; pkill -f 'moonshell shell' 2>/dev/null"
      .. "; pkill -x hypridle 2>/dev/null"
      .. "; pkill -f 'wl-paste --type text --watch cliphist' 2>/dev/null"
      .. "; pkill -f 'wl-paste --type image --watch cliphist' 2>/dev/null"
      .. "; wl-paste --type text --watch cliphist store &"
      .. "; wl-paste --type image --watch cliphist store &"
      .. "; true"
  )
end

hl.on("hyprland.start", function()
  kill_old_shell()
  require("default.hypr.autostart")
end)

-- Also launch now so `hyprctl reload` (no fresh session) starts the shell.
kill_old_shell()
hl.exec_cmd("omarchy-launch-shell")
