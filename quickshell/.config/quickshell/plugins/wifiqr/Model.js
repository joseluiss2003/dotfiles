// Parses the SwayP Wi-Fi QR helper output.
// The helper emits connection metadata followed by the path to a generated SVG.
function parseQrOutput(raw) {
  var lines = String(raw || "").trim().split(/\r?\n/).filter(function(line) { return line !== "" })
  var meta = { iface: "", security: "", ssid: "", svg: "" }

  for (var i = 0; i < lines.length; i++) {
    var fields = lines[i].split("\t")
    if (fields[0] === "meta") {
      meta.iface = fields[1] || ""
      meta.security = fields[2] || ""
      meta.ssid = fields.slice(3).join("\t")
    } else if (fields[0] === "svg") {
      meta.svg = fields.slice(1).join("\t")
    }
  }

  return meta
}

if (typeof module !== "undefined") {
  module.exports = { parseQrOutput: parseQrOutput }
}
