-- ============================================================================
-- >>> de-omarchy layer (added by de-omarchy installer — see README to revert)
-- Additive: loads Omarchy look & runtime AFTER this config, so every binding,
-- variable and autostart above keeps working. Conflicting keys stay yours.
-- Pre-install backup: see ~/.de-omarchy-backups/
-- ============================================================================
local __deo_path = os.getenv("OMARCHY_PATH")
if not __deo_path or __deo_path == "" then
  __deo_path = "/usr/share/de-omarchy"
end

local __deo_bootstrap = io.open(__deo_path .. "/default/hypr/bootstrap.lua", "r")
if __deo_bootstrap then
  __deo_bootstrap:close()
  dofile(__deo_path .. "/default/hypr/bootstrap.lua")
  require("hypr.deo-layer")
else
  print("[de-omarchy] runtime not found at " .. __deo_path .. " — layer skipped, host config unchanged")
end
-- <<< end de-omarchy layer >>>
