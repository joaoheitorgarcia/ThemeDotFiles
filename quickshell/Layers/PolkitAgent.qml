import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import "../Singletons" as Singletons

Item {
    id: polkitRoot

    //
    // Backend: PolkitAgent
    //
    PolkitAgent {
        id: agent

        Component.onCompleted: {
            console.debug("Polkit: initial isRegistered =", isRegistered)
        }

        onIsRegisteredChanged: {
            console.debug("Polkit: isRegistered changed:", isRegistered)
        }

        onAuthenticationRequestStarted: {
            console.debug("Polkit: auth request started, action:",
                          flow ? flow.actionId : "<none>")

            passwordField.text = ""
            errorLabel.visible = false
            polkitWindow.visible = true
            passwordField.forceActiveFocus()
        }
    }

    //
    // UI: modal popup
    //
    PanelWindow {
        id: polkitWindow

        // Show only while an auth flow is active
        visible: agent.isActive
        focusable: true
        aboveWindows: true
        color: "transparent"

        implicitWidth: Screen.width
        implicitHeight: Screen.height

        // Dark scrim behind the dialog
        Rectangle {
            anchors.fill: parent
            color: "#80000000" // 50% black overlay
        }

        // Centered dialog card
        Rectangle {
            id: dialogCard
            width: 380
            radius: 14
            color: Singletons.Theme ? Singletons.Theme.lightBackground : "#1c1c1c"
            border.color: Singletons.Theme ? Singletons.Theme.darkBase : "#3a3a3a"
            border.width: 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Title row with icon
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 6
                        color: Singletons.Theme ? Singletons.Theme.darkBase : "#333333"

                        Text {
                            anchors.centerIn: parent
                            text: ""          // lock-ish icon if you use Material Symbols
                            font.pixelSize: 14
                            color: Singletons.Theme ? Singletons.Theme.accent : "#ffffff"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Authentication required"
                            font.pixelSize: 18
                            font.bold: true
                            color: Singletons.Theme ? Singletons.Theme.darkBase : "#ffffff"
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: agent.flow ? agent.flow.actionId : ""
                            font.pixelSize: 11
                            color: Singletons.Theme ? Singletons.Theme.darkBase : "#aaaaaa"
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
                    color: Singletons.Theme ? Singletons.Theme.darkBase : "#dddddd"
                }

                // Supplementary message (often "Password for user …")
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: agent.flow ? agent.flow.supplementaryMessage : ""
                    visible: agent.flow && agent.flow.supplementaryMessage.length > 0
                    font.pixelSize: 12
                    color: agent.flow && agent.flow.supplementaryIsError
                           ? (Singletons.Theme ? Singletons.Theme.highlightRed : "#ff6666")
                           : (Singletons.Theme ? Singletons.Theme.darkBase : "#bbbbbb")
                }

                // Password field with proper background + focus border
                Rectangle {
                    id: passwordBg
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: Singletons.Theme ? Singletons.Theme.lightBackground : "#222222"
                    border.width: 2
                    border.color: passwordField.activeFocus
                                  ? (Singletons.Theme ? Singletons.Theme.accent : "#5aaaff")
                                  : (Singletons.Theme ? Singletons.Theme.darkBase : "#444444")

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
                        color: Singletons.Theme ? Singletons.Theme.darkBase : "#ffffff"
                        selectionColor: Singletons.Theme ? Singletons.Theme.accent : "#5aaaff"
                        cursorVisible: true

                        background: null   // we use passwordBg instead

                        enabled: agent.flow && agent.flow.isResponseRequired

                        onAccepted: submitResponse()
                    }
                }

                // Error label
                Text {
                    id: errorLabel
                    Layout.fillWidth: true
                    visible: false
                    text: "Authentication failed, try again."
                    color: Singletons.Theme ? Singletons.Theme.highlightRed : "#ff6666"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                // Buttons row
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true } // spacer

                    Button {
                        text: "Cancel"
                        onClicked: cancelRequest()
                    }

                    Button {
                        text: "OK"
                        enabled: passwordField.text.length > 0
                        onClicked: submitResponse()
                    }
                }
            }
        }

        // ESC handling (must be on an Item)
        Item {
            anchors.fill: parent
            focus: polkitWindow.visible
            Keys.onEscapePressed: cancelRequest()
        }
    }

    //
    // Helpers
    //
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

    //
    // React to AuthFlow property changes
    //
    Connections {
        target: agent.flow

        function onIsSuccessfulChanged() {
            if (!agent.flow || !agent.flow.isSuccessful)
                return
            console.debug("Polkit: auth successful")
            closeDialog()
        }

        function onFailedChanged() {
            if (!agent.flow || !agent.flow.failed)
                return
            console.debug("Polkit: auth failed")
            if (!errorLabel || !passwordField)
                return
            errorLabel.visible = true
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }

        function onIsCancelledChanged() {
            if (!agent.flow || !agent.flow.isCancelled)
                return
            console.debug("Polkit: auth cancelled")
            closeDialog()
        }
    }
}
