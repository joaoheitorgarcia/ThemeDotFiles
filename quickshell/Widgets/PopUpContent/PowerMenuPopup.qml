import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons

//TODO log out
Item {
    id: powerMenuContent
    implicitWidth: 200
    implicitHeight: 15 + (35 * actionList.model.length)

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

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
                    { id: "suspend", action: "systemctl suspend", label: "Sleep" },
                    { id: "hibernate", action: "systemctl hibernate", label: "Hibernate" },
                    { id: "lock", action: "lock", label: "Lock" },
                    { id: "reboot", action: "reboot", label: "Restart" },
                    { id: "shutdown", action: "shutdown now", label: "Shut Down" }
                ]

                delegate: Rectangle {
                    width: actionList.width
                    height: 32
                    color: hovered ? Singletons.Theme.accentSoftYellow : "transparent"
                    radius: 4

                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Singletons.Icon {
                            source: {
                                switch (modelData.id) {
                                case "suspend":
                                    return Singletons.Theme.iconPowerSuspend
                                case "hibernate":
                                    return Singletons.Theme.iconPowerHibernate
                                case "lock":
                                    return Singletons.Theme.iconPowerLock
                                case "reboot":
                                    return Singletons.Theme.iconPowerReboot
                                case "shutdown":
                                    return Singletons.Theme.iconPowerShutdow
                                default:
                                    return Singletons.Theme.iconPowerShutdow
                                }
                            }
                            size: 16
                            color: modelData.destructive
                                   ? Singletons.Theme.lowEnergy
                                   : Singletons.Theme.darkBase
                        }

                        Text {
                            text: modelData.label
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            color: Singletons.Theme.darkBase
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
                            Singletons.CommandRunner.run(modelData.action.split(' '))
                        }
                    }
                }
            }
        }
    }
}
