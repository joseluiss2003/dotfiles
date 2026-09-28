import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  // Kept as the canonical source ratio of the supplied artwork.
  readonly property real aspectRatio: 2528 / 600
  readonly property real logoWidth: Math.min(width, height * aspectRatio)
  readonly property real logoHeight: logoWidth / aspectRatio
  readonly property real logoX: (width - logoWidth) / 2
  readonly property real logoY: (height - logoHeight) / 2

  Image {
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark-source.svg"
    fillMode: Image.Stretch
    smooth: false
    mipmap: false
    sourceSize.width: 2528
    sourceSize.height: 600
  }
}
