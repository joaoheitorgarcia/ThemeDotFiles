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

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    property string password: ""
    property bool authenticating: false
    property bool showError: false

    onPasswordChanged: {
        showError = false

        if (passwordField && passwordField.text !== password) {
            passwordField.text = password
        }
    }

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

        onLockedChanged: {
            if (locked) {
                Qt.callLater(function() {
                    if (passwordField) {
                        passwordField.forceActiveFocus()
                    }
                })
            }
        }

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

                Rectangle {
                    id: unlockCard
                    readonly property int sidePadding: 14
                    readonly property int topPadding: 18
                    readonly property int bottomPadding: 14

                    width: Math.min(360, parent.width - 40)
                    implicitHeight: unlockLayout.implicitHeight + topPadding + bottomPadding
                    radius: 12
                    color: Singletons.MatugenTheme.surface
                    border.color: Singletons.MatugenTheme.outline
                    border.width: 1

                    anchors.centerIn: parent

                    ColumnLayout {
                        id: unlockLayout
                        x: unlockCard.sidePadding
                        y: unlockCard.topPadding
                        width: unlockCard.width - unlockCard.sidePadding * 2
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Singletons.Icon {
                                source: lockScreen.generalConfigs.icons.powerMenu.lock
                                size: 18
                                color: Singletons.MatugenTheme.surfaceText
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Session locked"
                                font.pixelSize: 16
                                font.bold: true
                                color: Singletons.MatugenTheme.surfaceText
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        Text {
                            text: Singletons.Time.time
                            font.pixelSize: 64
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            color: Singletons.MatugenTheme.surfaceText
                        }

                        Text {
                            text: Singletons.Time.date
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            color: Singletons.MatugenTheme.surfaceVariantText
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            radius: 0.5
                            color: Singletons.MatugenTheme.outlineVariant
                            opacity: 0.8
                        }

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            implicitHeight: 38
                            placeholderText: "Password"
                            placeholderTextColor: Singletons.MatugenTheme.surfaceVariantText
                            echoMode: TextInput.Password
                            inputMethodHints: Qt.ImhSensitiveData

                            leftPadding: 12
                            rightPadding: 12

                            enabled: !lockScreen.authenticating
                            color: Singletons.MatugenTheme.surfaceText
                            selectionColor: Singletons.MatugenTheme.secondaryContainer
                            selectedTextColor: Singletons.MatugenTheme.secondaryContainerText

                            onTextEdited: lockScreen.password = text
                            onAccepted: lockScreen.tryUnlock()

                            background: Rectangle {
                                radius: 6
                                color: Singletons.MatugenTheme.surface
                                border.width: 1
                                border.color: lockScreen.showError
                                              ? Singletons.MatugenTheme.errorColor
                                              : passwordField.activeFocus
                                                ? Singletons.MatugenTheme.secondary
                                                : Singletons.MatugenTheme.outlineVariant
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: lockScreen.authenticating ? "Unlocking…" : "Unlock"
                            enabled: !lockScreen.authenticating && lockScreen.password.length > 0
                            onClicked: lockScreen.tryUnlock()

                            background: Rectangle {
                                radius: 6
                                color: parent.enabled
                                       ? Singletons.MatugenTheme.secondaryContainer
                                       : Singletons.MatugenTheme.surfaceVariant
                                border.color: Singletons.MatugenTheme.outline
                                border.width: 1
                                opacity: parent.enabled ? 1 : 0.6
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled
                                       ? Singletons.MatugenTheme.secondaryContainerText
                                       : Singletons.MatugenTheme.surfaceVariantText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            visible: lockScreen.devMode
                            Layout.fillWidth: true
                            text: "Force Unlock (dev)"
                            onClicked: lockScreen.forceUnlock()

                            background: Rectangle {
                                radius: 6
                                color: Singletons.MatugenTheme.surfaceVariant
                                border.color: Singletons.MatugenTheme.outline
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                color: Singletons.MatugenTheme.surfaceText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text {
                            visible: lockScreen.showError
                            text: "Wrong password"
                            color: Singletons.MatugenTheme.errorColor
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
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
