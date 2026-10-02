import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null

  readonly property string locationName: "MADRID"
  readonly property real latitude: 40.4168
  readonly property real longitude: -3.7038

  property bool loading: false
  property bool available: false
  property real temperature: 0
  property real humidity: 0
  property real windSpeed: 0
  property int weatherCode: -1
  property string condition: "—"
  property string updatedAt: ""

  function conditionFor(code) {
    switch (Number(code)) {
    case 0: return "CLEAR"
    case 1: return "MAINLY CLEAR"
    case 2: return "PARTLY CLOUDY"
    case 3: return "OVERCAST"
    case 45:
    case 48: return "FOG"
    case 51:
    case 53:
    case 55: return "DRIZZLE"
    case 56:
    case 57: return "FREEZING DRIZZLE"
    case 61:
    case 63:
    case 65: return "RAIN"
    case 66:
    case 67: return "FREEZING RAIN"
    case 71:
    case 73:
    case 75:
    case 77: return "SNOW"
    case 80:
    case 81:
    case 82: return "SHOWERS"
    case 85:
    case 86: return "SNOW SHOWERS"
    case 95: return "THUNDERSTORM"
    case 96:
    case 99: return "THUNDERSTORM + HAIL"
    default: return "UNKNOWN"
    }
  }

  function refresh() {
    if (weatherProcess.running) return
    loading = true
    weatherProcess.running = true
  }

  function parseWeather(raw) {
    try {
      var data = JSON.parse(String(raw || ""))
      var current = data.current
      if (!current) throw new Error("missing current weather")

      root.temperature = Number(current.temperature_2m)
      root.humidity = Number(current.relative_humidity_2m)
      root.windSpeed = Number(current.wind_speed_10m)
      root.weatherCode = Number(current.weather_code)
      root.condition = root.conditionFor(root.weatherCode)
      root.updatedAt = String(current.time || "")
      root.available = true
    } catch (e) {
      root.available = false
      root.condition = "OFFLINE"
    }
    root.loading = false
  }

  Process {
    id: weatherProcess

    command: [
      "curl",
      "-fsSL",
      "--max-time", "10",
      "https://api.open-meteo.com/v1/forecast?latitude=40.4168&longitude=-3.7038&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=Europe%2FMadrid"
    ]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWeather(text)
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) {
        root.available = false
        root.loading = false
        root.condition = "OFFLINE"
      }
    }
  }

  Timer {
    interval: 15 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refresh()
}
