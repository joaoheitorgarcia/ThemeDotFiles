import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import "../Singletons" as Singletons

Item {
    id: polkitRoot

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

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
            id: dialogCard
            readonly property int sidePadding: 14
            readonly property int topPadding: 18
            readonly property int bottomPadding: 14

            width: Math.min(380, polkitWindow.width - 40)
            implicitHeight: contentLayout.implicitHeight + topPadding + bottomPadding
            radius: 12
            color: Singletons.MatugenTheme.surface
            border.color: Singletons.MatugenTheme.outline
            border.width: 1

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                id: contentLayout
                x: dialogCard.sidePadding
                y: dialogCard.topPadding
                width: dialogCard.width - dialogCard.sidePadding * 2
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Singletons.Icon {
                        source: polkitRoot.generalConfigs.icons.powerMenu.lock
                        size: 18
                        color: Singletons.MatugenTheme.surfaceText
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        font.pixelSize: 16
                        font.bold: true
                        color: Singletons.MatugenTheme.surfaceText
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: agent.flow ? agent.flow.actionId : ""
                    visible: text !== ""
                    font.pixelSize: 11
                    color: Singletons.MatugenTheme.surfaceVariantText
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: agent.flow ? agent.flow.message : ""
                    visible: agent.flow && agent.flow.message.length > 0
                    font.pixelSize: 13
                    color: Singletons.MatugenTheme.surfaceVariantText
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: agent.flow ? agent.flow.supplementaryMessage : ""
                    visible: agent.flow && agent.flow.supplementaryMessage.length > 0
                    font.pixelSize: 12
                    color: agent.flow && agent.flow.supplementaryIsError
                           ? Singletons.MatugenTheme.errorColor
                           : Singletons.MatugenTheme.surfaceVariantText
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    implicitHeight: 38
                    leftPadding: 12
                    rightPadding: 12

                    placeholderText: agent.flow
                                     ? agent.flow.inputPrompt
                                     : "Password"
                    placeholderTextColor: Singletons.MatugenTheme.surfaceVariantText

                    echoMode: agent.flow && !agent.flow.responseVisible
                              ? TextInput.Password
                              : TextInput.Normal

                    inputMethodHints: Qt.ImhSensitiveData
                    enabled: agent.flow && agent.flow.isResponseRequired
                    color: Singletons.MatugenTheme.surfaceText
                    selectionColor: Singletons.MatugenTheme.secondaryContainer
                    selectedTextColor: Singletons.MatugenTheme.secondaryContainerText

                    onAccepted: submitResponse()

                    background: Rectangle {
                        radius: 6
                        color: Singletons.MatugenTheme.surface
                        border.width: 1
                        border.color: passwordField.activeFocus
                                      ? red
                                      : Singletons.MatugenTheme.outlineVariant
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

                    Button {
                        text: "Cancel"
                        Layout.fillWidth: true
                        onClicked: cancelRequest()

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

                    Button {
                        text: "OK"
                        Layout.fillWidth: true
                        enabled: passwordField.text.length > 0
                        onClicked: submitResponse()

                        background: Rectangle {
                            radius: 6
                            color: enabled
                                   ? Singletons.MatugenTheme.secondaryContainer
                                   : Singletons.MatugenTheme.surfaceVariant
                            border.color: Singletons.MatugenTheme.outline
                            border.width: 1
                            opacity: enabled ? 1 : 0.6
                        }

                        contentItem: Text {
                            text: parent.text
                            color: enabled
                                   ? Singletons.MatugenTheme.secondaryContainerText
                                   : Singletons.MatugenTheme.surfaceVariantText
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
