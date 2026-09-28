import QtQuick
import QtQuick.Effects
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  readonly property real aspectRatio: 1264 / 300
  readonly property real logoWidth: Math.min(width - 10, (height - 10) * aspectRatio)
  readonly property real logoHeight: logoWidth / aspectRatio
  readonly property real logoX: (width - logoWidth) / 2
  readonly property real logoY: (height - logoHeight) / 2

  // Canonical wordmark asset traced from the approved reference.
  // Like Omarchy's canonical logo.svg, the artwork itself contains no theme
  // color: the shell supplies the color at render time.
  Image {
    id: logoSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark.svg"
    fillMode: Image.Stretch
    smooth: false
    mipmap: false
    visible: false
  }

  // Deep block extrusion. This keeps the physical depth from the approved
  // reference while remaining themeable.
  MultiEffect {
    id: shadow
    x: root.logoX + 5
    y: root.logoY + 6
    width: root.logoWidth
    height: root.logoHeight
    source: logoSource
    colorizationColor: root.shadowColor
    colorization: 1.0
    brightness: -0.15
  }

  // Main face: exactly the same semantic accent used by the lock clock.
  MultiEffect {
    id: face
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: logoSource
    colorizationColor: root.color
    colorization: 1.0
  }

  // A restrained top edge gives the mark the crisp light cap seen in the
  // approved reference without changing its silhouette.
  Rectangle {
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: Math.max(1, root.logoHeight * 0.025)
    color: root.highlightColor
    opacity: 0.9
  }
}