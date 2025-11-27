import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs   // for MessageDialog
import Quickshell.Bluetooth
import "../../Singletons" as Singletons

Item {
    id: bluetoothContent
    implicitWidth: 320
    implicitHeight: 300

    property QtObject adapter: Bluetooth.defaultAdapter

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 18
            anchors.bottomMargin: 0
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Bluetooth"
                    font.bold: true
                    font.pixelSize: 16
                    color: Singletons.Theme.darkBase
                }

                Item { Layout.fillWidth: true }

                Switch {
                    id: bluetoothSwitch
                    visible: adapter !== null
                    checked: adapter ? adapter.enabled : false
                    enabled: adapter !== null

                    onToggled: {
                        if (!adapter) return;
                        adapter.enabled = checked;
                    }

                    indicator: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 20
                        radius: height / 2
                        color: bluetoothSwitch.checked
                               ? Singletons.Theme.accentSoftYellow
                               : Singletons.Theme.accentSoft
                        border.color: Singletons.Theme.darkBase
                        border.width: 1.5

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            y: (parent.height - height) / 2
                            x: bluetoothSwitch.checked
                               ? parent.width - width - 3
                               : 3
                            color: Singletons.Theme.darkBase
                            border.color: Singletons.Theme.lightBackground
                            border.width: 2
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }

            // Text {
            //     visible: adapter?.discovering ?? false

            //     text: "Discovering..."
            //     color: Singletons.Theme.darkBase
            //     font.pixelSize: 11
            //     opacity: 0.8
            //     elide: Text.ElideRight
            // }

            ListView {
                id: actionList
                visible: adapter !== null
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: false
                model: adapter ? adapter.devices : []

                delegate: Rectangle {
                    width: actionList.width
                    height: 32
                    radius: 4
                    color: hovered ? Singletons.Theme.accentSoftYellow : "transparent"

                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Singletons.Icon {
                            source: Singletons.Theme.iconBluetooth
                            size: 16
                            color: modelData.destructive
                                   ? Singletons.Theme.lowEnergy
                                   : Singletons.Theme.darkBase
                        }

                        Text {
                            text: modelData.name
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 13
                        }

                        Singletons.Icon {
                            visible: modelData.pairing
                            source: Singletons.Theme.iconBluetoothPairing
                            size: 16
                            color: Singletons.Theme.darkBase
                        }

                        Singletons.Icon {
                            visible: modelData.paired
                            source: Singletons.Theme.iconBluetoothPaired
                            size: 16
                            color: Singletons.Theme.darkBase
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false

                        onClicked: {
                            modelData.pair()
                            modelData.connect()
                        }
                    }
                }
            }
        }
    }

    Connections {
      target: adapter
      function onStateChanged() {
        if (adapter.state === BluetoothAdapterState.Enabled) {
            adapter.discovering = true
        } else if (adapter.state === BluetoothAdapterState.Blocked) {
            console.log("Bluetooth Blocked by rfkill")
        }
      }
    }
}
