import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
    id: powerMenuContent
    implicitWidth: 200
    implicitHeight: 15 + (35 * actionList.model.length)

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 12
        color: Singletons.MatugenTheme.surfaceContainer
        border.color: Singletons.MatugenTheme.outline
        border.width: 1

        ColumnLayout {
            id: powerMenuLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            ListView {
                id: actionList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: false
                model: [
                    { id: "lock", action: "", label: "Lock" },
                    { id: "suspend", action: "systemctl suspend", label: "Sleep" },
                    { id: "hibernate", action: "systemctl hibernate", label: "Hibernate" },
                    { id: "reboot", action: "reboot", label: "Restart" },
                    { id: "shutdown", action: "shutdown now", label: "Shut Down" }
                ]

                delegate: Rectangle {
                    width: actionList.width
                    height: 32
                    color: hovered ? Singletons.MatugenTheme.surfaceVariant : "transparent"
                    radius: 6

                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Singletons.Icon {
                            source: {
                                switch (modelData.id) {
                                case "suspend":
                                    return generalConfigs.icons.powerMenu.suspend
                                case "hibernate":
                                    return generalConfigs.icons.powerMenu.hibernate
                                case "lock":
                                    return generalConfigs.icons.powerMenu.lock
                                case "reboot":
                                    return generalConfigs.icons.powerMenu.reboot
                                case "shutdown":
                                    return generalConfigs.icons.powerMenu.shutdown
                                default:
                                    return generalConfigs.icons.powerMenu.shutdown
                                }
                            }
                            size: 16
                            color: modelData.destructive
                                   ? Singletons.MatugenTheme.errorColor
                                   : Singletons.MatugenTheme.surfaceText
                        }

                        Text {
                            text: modelData.label
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            color: Singletons.MatugenTheme.surfaceText
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false

                        onClicked: {
                            if (modelData.id === "lock") {
                                Managers.SessionManager.lock()
                            } else {
                                Singletons.CommandRunner.run(modelData.action.split(' '))
                            }
                        }
                    }
                }
            }
        }
    }
}
