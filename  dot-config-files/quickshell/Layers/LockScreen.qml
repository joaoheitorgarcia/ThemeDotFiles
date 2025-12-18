import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick.Effects
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

Scope {
    id: lockScreen

    property bool devMode: false

    property string password: ""
    property bool authenticating: false
    property bool showError: false

    onPasswordChanged: showError = false

    PamContext {
        id: pam

        configDirectory: "../pam"
        config: "password.conf"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(lockScreen.password)
            }
        }

        onCompleted: function (result) {
            lockScreen.authenticating = false

            if (result === PamResult.Success) {
                sessionLock.locked = false
            } else {
                lockScreen.password = ""
                lockScreen.showError = true
            }
        }

        onError: function (err) {
            lockScreen.authenticating = false
            lockScreen.showError = true
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            Rectangle {
                anchors.fill: parent
                color: Singletons.MatugenTheme.surface

                //Blur Source
                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: Singletons.ConfigLoader.createWallpaperPath()
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                MultiEffect {
                    id: blur
                    anchors.fill: parent
                    source: wallpaper

                    blurEnabled: true
                    blur: 0.5
                    blurMax: 64
                    autoPaddingEnabled: false
                }

                Rectangle {
                    anchors.fill: parent
                    color: Singletons.MatugenTheme.surface
                    opacity: 0.45
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 16
                    width: 360

                    Text {
                        text: Singletons.Time.time
                        font.pixelSize: 72
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        color: Singletons.MatugenTheme.surfaceText
                    }

                    Text {
                        text: Singletons.Time.date
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        color: Singletons.MatugenTheme.surfaceVariantText
                    }

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData

                        enabled: !lockScreen.authenticating

                        text: lockScreen.password
                        onTextChanged: lockScreen.password = text

                        onAccepted: lockScreen.tryUnlock()

                        Component.onCompleted: forceActiveFocus()
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: lockScreen.authenticating ? "Unlocking…" : "Unlock"
                        enabled: !lockScreen.authenticating && lockScreen.password.length > 0
                        onClicked: lockScreen.tryUnlock()
                    }

                    //Force Unlock for Dev Mode
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: lockScreen.devMode
                        text: "Force Unlock (dev)"
                        onClicked: lockScreen.forceUnlock()
                    }

                    Text {
                        visible: lockScreen.showError
                        text: "Wrong password"
                        color: Singletons.MatugenTheme.errorColor
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    function tryUnlock() {
        if (password.length === 0 || authenticating)
            return

        if (!pam.start()) {
            authenticating = false
            showError = true
            return
        }

        authenticating = true
    }

    function lock() {
        if (!sessionLock.locked) {
            Managers.PopupManager.closeAll()
            password = ""
            showError = false
            authenticating = false
            sessionLock.locked = true
        }
    }

    function unlock() {
        sessionLock.locked = false
    }

    //DEV MODE ON
    function forceUnlock() {
        console.warn("DEV: force unlocking session lock")
        sessionLock.locked = false
        password = ""
        showError = false
        authenticating = false
    }
}
