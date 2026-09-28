import QtQuick
import QtQuick.Effects
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  // Keep the exact aspect ratio of the user's original SVG.
  readonly property real aspectRatio: 2528 / 600
  readonly property real logoWidth: Math.min(width, height * aspectRatio)
  readonly property real logoHeight: logoWidth / aspectRatio
  readonly property real logoX: (width - logoWidth) / 2
  readonly property real logoY: (height - logoHeight) / 2

  Image {
    id: depthSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark-depth.svg"
    fillMode: Image.Stretch
    smooth: false
    mipmap: false
    visible: false
  }

  Image {
    id: faceSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark-face.svg"
    fillMode: Image.Stretch
    smooth: false
    mipmap: false
    visible: false
  }

  MultiEffect {
    id: depth
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: depthSource
    colorizationColor: root.shadowColor
    colorization: 1.0
  }

  MultiEffect {
    id: face
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: faceSource
    colorizationColor: root.color
    colorization: 1.0
  }
}
