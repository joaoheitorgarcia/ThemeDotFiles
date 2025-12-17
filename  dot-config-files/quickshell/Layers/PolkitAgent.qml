import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import "../Singletons" as Singletons

Item {
    id: polkitRoot

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            passwordField.text = ""
            errorLabel.visible = false
            polkitWindow.visible = true
            passwordField.forceActiveFocus()
        }
    }

    PanelWindow {
        id: polkitWindow

        // Show only while an auth flow is active
        visible: agent.isActive
        focusable: true
        aboveWindows: true
        color: "transparent"

        implicitWidth: Screen.width
        implicitHeight: Screen.height

        Rectangle {
            anchors.fill: parent
            color: "#80000000" // 50% black overlay
        }

        Rectangle {
            id: dialogCard
            width: 380
            radius: 14
            color: Singletons.MatugenTheme.surfaceText
            border.color: Singletons.MatugenTheme.outlineVariant
            border.width: 1

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 6
                        color: Singletons.MatugenTheme.surfaceContainer

                        Text {
                            anchors.centerIn: parent
                            text: ""          // lock-ish icon if you use Material Symbols
                            font.pixelSize: 14
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                        text: "Authentication required"
                        font.pixelSize: 18
                        font.bold: true
                        color: Singletons.MatugenTheme.surfaceContainer
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: agent.flow ? agent.flow.actionId : ""
                        font.pixelSize: 11
                        color: Singletons.MatugenTheme.surfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            // Main message from polkit
            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: agent.flow ? agent.flow.message : ""
                visible: agent.flow && agent.flow.message.length > 0
                font.pixelSize: 12
                color: Singletons.MatugenTheme.surfaceVariant
            }

            // Supplementary message (often "Password for user …")
            Text {
                Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                text: agent.flow ? agent.flow.supplementaryMessage : ""
                visible: agent.flow && agent.flow.supplementaryMessage.length > 0
                font.pixelSize: 12
                color: agent.flow && agent.flow.supplementaryIsError
                       ? Singletons.MatugenTheme.errorColor
                       : Singletons.MatugenTheme.surfaceVariant
            }

            // Password field with proper background + focus border
            Rectangle {
                id: passwordBg
                Layout.fillWidth: true
                height: 38
                radius: 8
                color: Singletons.MatugenTheme.surfaceText
                border.width: 1
                border.color: passwordField.activeFocus
                              ? Singletons.MatugenTheme.secondary
                              : Singletons.MatugenTheme.outlineVariant

                    TextField {
                        id: passwordField
                        anchors.fill: parent
                        anchors.margins: 6

                        placeholderText: agent.flow
                                         ? agent.flow.inputPrompt
                                         : "Password"

                        echoMode: agent.flow && !agent.flow.responseVisible
                                  ? TextInput.Password
                                  : TextInput.Normal

                        inputMethodHints: Qt.ImhSensitiveData
                        cursorVisible: true
                        background: null   // we use passwordBg instead

                        enabled: agent.flow && agent.flow.isResponseRequired
                        onAccepted: submitResponse()
                    }
                }

                Text {
                    id: errorLabel
                    Layout.fillWidth: true
                    visible: false
                    text: "Authentication failed, try again."
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    color: Singletons.MatugenTheme.errorColor
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true } // spacer

                    Button {
                        text: "Cancel"
                        onClicked: cancelRequest()

                    background: Rectangle {
                        radius: 8
                        color: Singletons.MatugenTheme.surfaceVariantText
                        border.color: Singletons.MatugenTheme.outlineVariant
                        border.width: 1
                    }

                    contentItem: Text {
                        text: parent.text
                        color: Singletons.MatugenTheme.surfaceContainer
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                    Button {
                        text: "OK"
                        enabled: passwordField.text.length > 0
                        onClicked: submitResponse()

                    background: Rectangle {
                        radius: 8
                        color: enabled
                               ? Singletons.MatugenTheme.secondary
                               : Singletons.MatugenTheme.surfaceVariantText
                        border.color: Singletons.MatugenTheme.outlineVariant
                        border.width: 1
                        opacity: enabled ? 1 : 0.6
                        }

                    contentItem: Text {
                        text: parent.text
                        color: enabled
                               ? Singletons.MatugenTheme.secondaryText
                               : Singletons.MatugenTheme.surfaceContainer
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: polkitWindow.visible
            Keys.onEscapePressed: cancelRequest()
        }
    }

    function resetDialog() {
        if (!passwordField || !errorLabel)
            return
        passwordField.text = ""
        errorLabel.visible = false
    }

    function closeDialog() {
        resetDialog()
        polkitWindow.visible = false
    }

    function submitResponse() {
        if (!agent.flow)
            return
        agent.flow.submit(passwordField.text)
    }

    function cancelRequest() {
        if (agent.flow) {
            agent.flow.cancelAuthenticationRequest()
        }
        closeDialog()
    }

    Connections {
        target: agent.flow

        function onIsSuccessfulChanged() {
            if (!agent.flow || !agent.flow.isSuccessful)
                return
            closeDialog()
        }

        function onFailedChanged() {
            if (!agent.flow || !agent.flow.failed)
                return

            if (!errorLabel || !passwordField)
                return

            errorLabel.visible = true
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }

        function onIsCancelledChanged() {
            if (!agent.flow || !agent.flow.isCancelled)
                return

            closeDialog()
        }
    }
}
