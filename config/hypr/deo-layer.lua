local require_optional = require("default.hypr.require_optional")
require("default.hypr.helpers")
require("default.hypr.envs")
require("default.hypr.looknfeel")

-- Re-enable resize on border (Omarchy defaults to false, but we want it)
hl.config({ general = { resize_on_border = true } })

require_optional.module("omarchy.current.theme.hyprland")
require("default.hypr.windows")
require("hypr.deo-bindings")
require("hypr.deo-autostart")
