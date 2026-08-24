.pragma library
// Bar style presets. A preset is a token set the bar surface reads to repaint
// itself; colors are plain #RRGGBB or named Color tokens (accent, foreground,
// background, barBackground, barText, selection, muted). ORDER is the canonical
// cycle order (also embedded in omarchy-barstyle-list and shell.qml).
//
// Classic QML JS library (.pragma Library on line 1): the QML engine rejects ES
// module `export` statements in plain .js files, so every top-level
// const/function is simply reached through the import namespace
// (BarStyles.resolve, ...).

const ORDER = [
  "classic", "floating-islands", "glass", "capsule", "terminal-boxed",
  "minimal-line", "gradient-wave", "oled-black", "soft-rounded", "segmented"
]

const PRESETS = {
  classic: { label: "Classic", description: "Full-width solid bar, the upstream Omarchy default.", float: false, margin: 0, radius: 0, borderWidth: 0, borderColor: "none", bgAlpha: null, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  "floating-islands": { label: "Floating Islands", description: "Left/right sections float as rounded islands with a gap.", float: true, margin: 8, radius: 14, borderWidth: 1, borderColor: "foreground", bgAlpha: 0.9, gradient: null, islands: true, islandGap: 10, islandPadding: 8, underline: false },
  glass: { label: "Glass", description: "Translucent full bar with a hairline outline.", float: true, margin: 8, radius: 16, borderWidth: 1, borderColor: "foreground", bgAlpha: 0.5, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  capsule: { label: "Capsule", description: "Single centered rounded slab, fully floating.", float: true, margin: 12, radius: 999, borderWidth: 1, borderColor: "accent", bgAlpha: 0.95, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  "terminal-boxed": { label: "Terminal Boxed", description: "Sharp corners, full band, bold accent outline.", float: false, margin: 0, radius: 2, borderWidth: 1, borderColor: "accent", bgAlpha: null, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  "minimal-line": { label: "Minimal Line", description: "No bar fill, just a slim accent underline.", float: false, margin: 0, radius: 0, borderWidth: 0, borderColor: "none", bgAlpha: 0, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: true },
  "gradient-wave": { label: "Gradient Wave", description: "Horizontal accent-to-background gradient band.", float: false, margin: 0, radius: 0, borderWidth: 0, borderColor: "none", bgAlpha: null, gradient: { from: "accent", to: "barBackground", vertical: false }, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  "oled-black": { label: "OLED Black", description: "Pure black bar with a bright accent bottom rule.", float: false, margin: 0, radius: 0, borderWidth: 0, borderColor: "none", bgAlpha: null, gradient: { from: "#000000", to: "#000000", vertical: false }, islands: false, islandGap: 0, islandPadding: 0, underline: true },
  "soft-rounded": { label: "Soft Rounded", description: "Gently rounded, slightly translucent, no border.", float: true, margin: 4, radius: 12, borderWidth: 0, borderColor: "none", bgAlpha: 0.85, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false },
  segmented: { label: "Segmented", description: "Squared side islands with their own outlines.", float: false, margin: 0, radius: 6, borderWidth: 1, borderColor: "accent", bgAlpha: null, gradient: null, islands: true, islandGap: 6, islandPadding: 6, underline: false }
}

const BASE = { float: false, margin: 0, radius: 0, borderWidth: 0, borderColor: "none", bgAlpha: null, gradient: null, islands: false, islandGap: 0, islandPadding: 0, underline: false }

function merge(base, over) {
  var out = {}
  for (var k in base) out[k] = base[k]
  for (var k in over) if (over[k] !== undefined) out[k] = over[k]
  return out
}

function resolve(config) {
  var name = (config && config.styleName) || "classic"
  var preset = PRESETS[name] || PRESETS.classic
  return merge(BASE, preset)
}

function list() {
  var out = []
  for (var i = 0; i < ORDER.length; i++) out.push({ id: ORDER[i], label: PRESETS[ORDER[i]].label, description: PRESETS[ORDER[i]].description })
  return out
}

function indexOf(id) {
  for (var i = 0; i < ORDER.length; i++) if (ORDER[i] === id) return i
  return -1
}

function step(id, dir) {
  var i = indexOf(id)
  if (i === -1) i = 0
  var n = (i + (dir >= 0 ? 1 : -1) + ORDER.length) % ORDER.length
  return ORDER[n]
}
