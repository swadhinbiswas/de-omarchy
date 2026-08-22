// Monitor management functions
// Reads hyprctl JSON, sends commands to configure monitors

function parseMonitors(jsonStr) {
  try {
    var monitors = JSON.parse(jsonStr)
    var result = []
    for (var i = 0; i < monitors.length; i++) {
      var m = monitors[i]
      var transform = m.transform || 0
      var rotation = [0, 90, 180, 270][transform % 4]
      result.push({
        name: m.name || "",
        description: m.description || "",
        width: m.width || 0,
        height: m.height || 0,
        refreshRate: Math.round(m.refreshRate || 0),
        x: m.x || 0,
        y: m.y || 0,
        scale: m.scale || 1,
        transform: transform,
        rotation: rotation,
        focused: !!m.focused,
        activeWorkspace: m.activeWorkspace ? m.activeWorkspace.id : -1,
        make: m.make || "",
        model: m.model || ""
      })
    }
    return result
  } catch (e) {
    return []
  }
}

function rotationToTransform(degrees) {
  var map = { 0: 0, 90: 1, 180: 2, 270: 3 }
  return map[degrees] || 0
}

function setMonitorPosition(name, x, y) {
  return "hyprctl keyword monitor " + name + ",preferred," + x + "x" + y + ",1"
}

function setMonitorScale(name, scale) {
  return "hyprctl keyword monitor " + name + ",preferred,auto," + scale
}

function setMonitorRotation(name, transform) {
  return "hyprctl keyword monitor " + name + ",preferred,auto,1,transform," + transform
}

function setMonitorConfig(name, mode, x, y, scale, transform) {
  var pos = x + "x" + y
  var cmd = "hyprctl keyword monitor " + name + "," + mode + "," + pos + "," + scale
  if (transform && transform !== 0) {
    cmd += ",transform," + transform
  }
  return cmd
}

function getBrightnessPath(monitorName) {
  // DDC/CI path via i2c
  var base = "/sys/class/backlight/"
  // Try to match by connector name
  var paths = [
    "/sys/class/backlight/amdgpu_bl1/brightness",
    "/sys/class/backlight/intel_backlight/brightness",
    "/sys/class/backlight/acpi_video0/brightness"
  ]
  for (var i = 0; i < paths.length; i++) {
    if (typeof paths[i] === "string") return paths[i]
  }
  return ""
}

function getBrightnessMax(path) {
  var maxPath = path.replace("/brightness", "/max_brightness")
  return "cat " + maxPath + " 2>/dev/null || echo 100"
}

function setBrightness(path, percent) {
  var maxPath = path.replace("/brightness", "/max_brightness")
  return "max=$(cat " + maxPath + " 2>/dev/null || echo 100); "
    + "val=$((max * " + percent + " / 100)); "
    + "echo $val | tee " + path + " 2>/dev/null"
}

function setWallpaper(monitorName, wallpaperPath) {
  // swww or hyprpaper or omarchy shell background
  return "swww img " + wallpaperPath + " 2>/dev/null || true"
}
