import QtQuick
import qs.core

Item {
  id: root

  property QtObject bar: null
  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property color trackColor: Util.alpha(Color.bar.text, 0.18)
  property color fillColor: Color.bar.text
  property color knobColor: Color.bar.text
  property bool dragging: false
  property real trackHeight: Math.max(6, Math.round(Style.spacing.controlHeight * 0.18))
  property real liveValue: value
  property int segmentCount: 32
  property real segmentGap: Style.space(2)

  onValueChanged: if (!dragging) liveValue = value

  signal moved(real value)
  signal released(real value)
  signal rightClicked()

  implicitWidth: Style.space(200)
  implicitHeight: Math.max(Style.space(22), trackHeight + Style.spacing.md)

  readonly property real range: Math.max(0.0001, maximum - minimum)
  readonly property real progress: Math.max(0, Math.min(1, (liveValue - minimum) / range))
  readonly property bool _hot: mouseArea.containsMouse || root.dragging

  Item {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: root.trackHeight

    Row {
      anchors.fill: parent
      spacing: root.segmentGap

      Repeater {
        model: root.segmentCount

        Rectangle {
          required property int index

          width: (track.width - root.segmentGap * (root.segmentCount - 1))
                  / root.segmentCount
          height: track.height
          radius: 0
          color: index < Math.ceil(root.progress * root.segmentCount)
                 ? root.fillColor
                 : root.trackColor

          Behavior on color {
            enabled: !root.dragging
            ColorAnimation { duration: 90 }
          }
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    function valueFromX(x) {
      var clamped = Math.max(0, Math.min(track.width, x))
      var raw = root.minimum + (clamped / track.width) * root.range
      if (root.integer) raw = Math.round(raw)
      return Math.max(root.minimum, Math.min(root.maximum, raw))
    }

    onPressed: function(mouse) {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = true
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }

    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.rightClicked()
    }

    onPositionChanged: function(mouse) {
      if (!root.dragging) return
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }

    onReleased: function(mouse) {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = false
      root.released(root.liveValue)
      root.liveValue = root.value
    }

    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? root.step : -root.step
      var next = Math.max(root.minimum, Math.min(root.maximum, root.liveValue + delta))
      if (root.integer) next = Math.round(next)
      root.liveValue = next
      root.moved(next)
      root.released(next)
    }
  }
}
