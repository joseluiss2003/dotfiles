// Small, dependency-free parsers for the SwayP system inspector.
// Runtime data comes from /proc, swaymsg and optional nvidia-smi; this file
// deliberately contains no UI policy.

function number(value, fallback) {
  var n = Number(value)
  return isFinite(n) ? n : fallback
}

function parseCpu(raw) {
  var line = String(raw || "").split("\n")[0].trim()
  var parts = line.split(/\s+/)
  if (parts.length < 5 || parts[0] !== "cpu") return null

  var total = 0
  for (var i = 1; i < parts.length; i++) total += number(parts[i], 0)

  return {
    total: total,
    idle: number(parts[4], 0) + (parts.length > 5 ? number(parts[5], 0) : 0)
  }
}

function cpuPercent(previous, current) {
  if (!previous || !current) return 0
  var totalDelta = current.total - previous.total
  var idleDelta = current.idle - previous.idle
  if (totalDelta <= 0) return 0
  return Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)))
}

function parseMemory(raw) {
  var total = 0
  var available = 0
  var lines = String(raw || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    var match = lines[i].match(/^([A-Za-z_]+):\s+(\d+)/)
    if (!match) continue
    var kb = number(match[2], 0)
    if (match[1] === "MemTotal") total = kb
    else if (match[1] === "MemAvailable") available = kb
  }

  if (total <= 0) return null
  return {
    total: total,
    available: available,
    used: Math.max(0, total - available),
    percent: Math.max(0, Math.min(100, 100 * (total - available) / total))
  }
}

function parseLoad(raw) {
  var value = String(raw || "").trim().split(/\s+/)[0]
  return number(value, 0)
}

function parseOutputs(raw) {
  try {
    var parsed = JSON.parse(String(raw || "[]"))
    if (!Array.isArray(parsed)) return []
    return parsed.map(function(output) {
      return {
        name: String(output.name || ""),
        active: output.active === true,
        focused: output.focused === true,
        width: output.current_mode && output.current_mode.width
          ? number(output.current_mode.width, 0)
          : 0,
        height: output.current_mode && output.current_mode.height
          ? number(output.current_mode.height, 0)
          : 0,
        refresh: output.current_mode && output.current_mode.refresh
          ? number(output.current_mode.refresh, 0) / 1000
          : 0,
        scale: number(output.scale, 1),
        workspace: String(output.current_workspace || "")
      }
    }).filter(function(output) { return output.name !== "" })
  } catch (e) {
    return []
  }
}

function parseTree(raw) {
  var result = {
    windows: 0,
    workspaces: 0,
    focused: "",
    focusedWorkspace: ""
  }

  function walk(node, workspace) {
    if (!node) return

    var nextWorkspace = workspace
    if (String(node.type || "") === "workspace") {
      result.workspaces++
      nextWorkspace = String(node.name || "")
    }

    if (node.focused === true) {
      var app = String(node.app_id || "")
      var klass = node.window_properties ? String(node.window_properties.class || "") : ""
      var title = String(node.name || "")
      result.focused = app || klass || title || result.focused
      result.focusedWorkspace = nextWorkspace
    }

    // Leaf containers with a pid represent actual client windows in Sway's tree.
    if (String(node.type || "") === "con" && number(node.pid, 0) > 0 && (!node.nodes || node.nodes.length === 0))
      result.windows++

    var nodes = Array.isArray(node.nodes) ? node.nodes : []
    var floating = Array.isArray(node.floating_nodes) ? node.floating_nodes : []
    for (var i = 0; i < nodes.length; i++) walk(nodes[i], nextWorkspace)
    for (var j = 0; j < floating.length; j++) walk(floating[j], nextWorkspace)
  }

  try {
    walk(JSON.parse(String(raw || "{}")), "")
  } catch (e) {
    return result
  }

  return result
}

function parseGpu(raw) {
  var line = String(raw || "").trim().split("\n")[0].trim()
  if (!line) return null

  var parts = line.split(/,\s*/)
  if (parts.length < 6) return null

  return {
    name: parts[0].trim(),
    usage: number(parts[1], 0),
    memoryUsed: number(parts[2], 0),
    memoryTotal: number(parts[3], 0),
    temperature: number(parts[4], 0),
    power: number(parts[5], 0)
  }
}

function formatBytesFromKiB(kib) {
  var gb = number(kib, 0) / 1024 / 1024
  if (gb >= 10) return gb.toFixed(1) + " GB"
  return gb.toFixed(2) + " GB"
}

function formatUptime(seconds) {
  var total = Math.max(0, Math.floor(number(seconds, 0)))
  var days = Math.floor(total / 86400)
  total %= 86400
  var hours = Math.floor(total / 3600)
  total %= 3600
  var minutes = Math.floor(total / 60)

  if (days > 0) return days + "d " + hours + "h"
  if (hours > 0) return hours + "h " + minutes + "m"
  return minutes + "m"
}

function formatRefresh(hz) {
  var value = number(hz, 0)
  if (value <= 0) return "—"
  return value >= 100 ? value.toFixed(0) + " Hz" : value.toFixed(1) + " Hz"
}

function formatScale(scale) {
  var value = number(scale, 1)
  return value === Math.round(value) ? value.toFixed(0) + "×" : value.toFixed(2) + "×"
}

function formatLoad(load) {
  return number(load, 0).toFixed(2)
}
