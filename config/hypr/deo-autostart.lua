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
-- ============================================================================

hl.on("hyprland.start", function()
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
end)

require("default.hypr.autostart")
