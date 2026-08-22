-- ============================================================================
--  de-omarchy display layout — generated from LIVE `hyprctl monitors all`
--  output on the source machine (2026-08-22). This file is documentation +
--  a ready-made module; the installer does NOT force it onto other machines
--  unless they run scripts/apply-own-monitors.sh after editing it.
--
--  Layout: DP-3 (left) · HDMI-A-3 (middle) · DP-4 (right, portrait)
-- ============================================================================

return {
    primary   = { output = "DP-3",    mode = "1920x1080@60",    position = "0x0",        scale = 1, transform = 0 },
    secondary = { output = "HDMI-A-3", mode = "1920x1080@60",   position = "1920x0",     scale = 1, transform = 0 },
    tertiary  = { output = "DP-4",    mode = "1920x1080@100",   position = "3840x-420",  scale = 1, transform = 3 },
}
