import QtQuick
import QtQuick.Effects
import qs.core
import qs.ui

Item {
  id: root

  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property bool displaysBlank: false
  property bool powerSaverActive: false
  property string passwordText: ""
  property string userName: ""
  property date currentTime: new Date()
  property bool syncingPasswordText: false
  property real revealProgress: 0
  property int shakeOffset: 0

  readonly property string placeholderText: "Enter Password"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)

  readonly property real fingerprintReserve: fingerprintConfigured
    ? Math.round(fingerprintIcon.implicitWidth + 12)
    : 0

  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1

  readonly property bool showPasswordCursor:
    inputEnabled &&
    !authenticatingPassword &&
    failureMessage.length === 0

  readonly property bool errorState:
    failureMessage.length > 0

  readonly property var inputBorderSpec:
    errorState
      ? Border.surfaceSpec(
          "lock",
          "border-error",
          Color.lock.borderError,
          outlineThickness,
          "border-alpha"
        )
      : Border.surfaceSpec(
          "lock",
          "border-active",
          Color.lock.borderActive,
          outlineThickness,
          "border-alpha"
        )

  readonly property bool video:
    Util.isVideoPath(root.backgroundPath)

  readonly property bool feedActive:
    root.video &&
    root.loadBackground &&
    !root.displaysBlank &&
    !root.powerSaverActive

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  ParallelAnimation {
    id: revealAnimation

    NumberAnimation {
      target: root
      property: "revealProgress"
      from: 0
      to: 1
      duration: Style.fullscreen.settleDuration + 80
      easing.type: Easing.OutCubic
    }
  }

  SequentialAnimation {
    id: shakeAnimation

    NumberAnimation { target: root; property: "shakeOffset"; to: -10; duration: 45; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 55; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: -5; duration: 45; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 3; duration: 35; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
  }

  onInputEnabledChanged: {
    if (inputEnabled) {
      revealAnimation.restart()
      Qt.callLater(forcePasswordFocus)
    }
  }

  onFailureMessageChanged: {
    if (failureMessage.length > 0)
      shakeAnimation.restart()
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.currentTime = new Date()
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged:
    syncPasswordText()

  Component.onCompleted: {
    syncPasswordText()
    revealAnimation.restart()
    if (inputEnabled)
      Qt.callLater(forcePasswordFocus)
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Color.bar.background

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenterOffset: root.shakeOffset
      spacing: 40
      opacity: root.revealProgress
      transform: [
        Translate {
          y: (1 - root.revealProgress) * 22
        },
        Scale {
          origin.x: parent.width / 2
          origin.y: parent.height / 2
          xScale: 0.97 + (root.revealProgress * 0.03)
          yScale: 0.97 + (root.revealProgress * 0.03)
        }
      ]

      SwayPWordmark {
        width: 760
        height: 180
        anchors.horizontalCenter: parent.horizontalCenter
        color: Color.brand.accent
        highlightColor: Color.brand.highlight
        shadowColor: Color.brand.depth
      }

      Item {
        width: inputField.width + 48 + 12
        height: inputField.height
        anchors.horizontalCenter: parent.horizontalCenter

        BorderSurface {
          id: inputField

          width: 360
          height: 68
          anchors.horizontalCenter: parent.horizontalCenter

          color: Color.lock.background
          borderSpec: root.inputBorderSpec
          radius: 0
          clip: true

          TextInput {
            id: passwordInput

            anchors.fill: parent
            anchors.topMargin: inputField.borderTop
            anchors.rightMargin: inputField.borderRight + 18
            anchors.bottomMargin: inputField.borderBottom
            anchors.leftMargin: inputField.borderLeft + 18

            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            activeFocusOnPress: true
            clip: true
            enabled: root.inputEnabled && !root.authenticatingPassword
            readOnly: root.authenticatingPassword
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            passwordMaskDelay: 0
            color: Color.lock.text
            selectionColor: Color.lock.selection
            selectedTextColor: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: text.length > 0
              ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale))
              : root.fieldFontSize
            font.letterSpacing: text.length > 0
              ? root.passwordDotLetterSpacing * root.passwordDotScale
              : 0
            cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0

            cursorDelegate: Rectangle {
              width: 2
              color: Color.lock.text
              visible: passwordInput.cursorVisible
            }

            onTextChanged: {
              if (!root.syncingPasswordText)
                root.passwordTextEdited(text)
              if (text.length > 0)
                root.wakeRequested()
              if (text.length > 0 && root.failureMessage.length > 0)
                root.clearFailureRequested()
            }

            onAccepted: {
              var submitted = root.passwordText
              root.passwordTextEdited("")
              if (submitted.length > 0)
                root.submitPassword(submitted)
            }

            Keys.onPressed: function(event) {
              root.wakeRequested()
              if (
                event.key === Qt.Key_Escape ||
                (
                  event.modifiers &
                  Qt.ControlModifier &&
                  event.key === Qt.Key_U
                )
              ) {
                root.passwordTextEdited("")
                event.accepted = true
              }
            }
          }

          Text {
            anchors.fill: passwordInput
            text: root.authenticatingPassword
              ? "Checking…"
              : (
                  root.failureMessage.length > 0
                    ? root.failureMessage
                    : root.placeholderText
                )
            visible: passwordInput.text.length === 0
            color: root.authenticatingPassword
              ? Color.lock.text
              : (
                  root.failureMessage.length > 0
                    ? Color.lock.textError
                    : Color.lock.placeholder
                )
            font.family: Style.font.family
            font.pixelSize: root.fieldFontSize
            font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }

        Item {
          width: 48
          height: 68
          anchors.left: inputField.right
          anchors.leftMargin: 12
          anchors.verticalCenter: inputField.verticalCenter

          Text {
            anchors.fill: parent
            text: root.authenticatingPassword ? "󰦪" : "󰌾"
            color: root.failureMessage.length > 0
              ? Color.lock.textError
              : Color.lock.text
            font.family: Style.font.family
            font.pixelSize: 30
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      onPositionChanged: root.wakeRequested()
    }
  }
}
