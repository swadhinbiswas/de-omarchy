-- ============================================================================
--  de-omarchy layer — Omarchy look & runtime over an existing Hyprland setup
--
--  Loaded LAST from hyprland.lua (after the host config's own modules), so:
--    * Omarchy looknfeel overrides host visuals (gaps/borders/animations)
--    * Host keybindings stay intact; only non-conflicting Omarchy binds are
--      added (see keybindings/KEYMAP.md in the de-omarchy repo)
--  Remove the marked block at the end of hyprland.lua to fully revert.
-- ============================================================================

local require_optional = require("default.hypr.require_optional")

-- Environment: OMARCHY_PATH, PATH with $OMARCHY_PATH/bin first, Wayland flags.
require("default.hypr.envs")

-- The Omarchy look: gaps, borders, animations, groupbar.
require("default.hypr.looknfeel")

-- Theme-generated Hyprland color overrides (written by omarchy-theme-set).
require_optional.module("omarchy.current.theme.hyprland")

-- Window rules and defaults (opacity tags, xwayland fixes).
require("default.hypr.windows")

-- Curated Omarchy bindings that do not collide with the host keymap.
require("hypr.deo-bindings")

-- Shell bridge: hand the desktop over to the Omarchy Quickshell shell.
require("hypr.deo-autostart")
