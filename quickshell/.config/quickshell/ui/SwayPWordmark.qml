import QtQuick
import QtQuick.Effects
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  // Kept for compatibility with the existing LockView API.
  // The rendered asset now contains its own finished face/depth masks.
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  readonly property real aspectRatio: 1972 / 586
  readonly property real logoWidth: Math.min(width, height * aspectRatio)
  readonly property real logoHeight: logoWidth / aspectRatio
  readonly property real logoX: (width - logoWidth) / 2
  readonly property real logoY: (height - logoHeight) / 2

  // Rendered lockscreen wordmark, split into two masks so each part can
  // follow SwayP's semantic theme colors without altering the artwork.
  Image {
    id: depthSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark-depth.svg"
    fillMode: Image.Stretch
    smooth: true
    mipmap: true
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

  Image {
    id: faceSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark-face.svg"
    fillMode: Image.Stretch
    smooth: true
    mipmap: true
    visible: false
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
