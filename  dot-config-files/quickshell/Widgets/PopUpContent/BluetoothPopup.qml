import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../Singletons" as Singletons

Item {
    id: bluetoothContent
    implicitWidth: 320
    implicitHeight: 300

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    property QtObject adapter: Bluetooth.defaultAdapter

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Singletons.MatugenTheme.surfaceContainer
        border.color: Singletons.MatugenTheme.outline
        border.width: 1

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
                    color: Singletons.MatugenTheme.surfaceText
                }

                Item { Layout.fillWidth: true }

                Switch {
                    id: bluetoothSwitch
                    visible: adapter !== null
                    checked: false
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
                               ? Singletons.MatugenTheme.secondary
                               : Singletons.MatugenTheme.surfaceText
                        border.color: Singletons.MatugenTheme.outline
                        border.width: 1

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            y: (parent.height - height) / 2
                            x: bluetoothSwitch.checked
                               ? parent.width - width - 3
                               : 3
                            color: Singletons.MatugenTheme.surfaceContainer
                            border.color: Singletons.MatugenTheme.outlineVariant
                            border.width: 1
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }

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
                    radius: 6
                    color: modelData.paired || modelData.pairing
                           ? Singletons.MatugenTheme.secondaryContainer
                           : hovered
                             ? Singletons.MatugenTheme.surfaceVariant
                             : "transparent"

                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Singletons.Icon {
                            source: generalConfigs.icons.bluetooth.bluetooth
                            size: 16
                            color: modelData.destructive
                                   ? Singletons.MatugenTheme.errorColor
                                   : Singletons.MatugenTheme.surfaceText
                        }

                        Text {
                            text: modelData.name
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            color: Singletons.MatugenTheme.surfaceText
                            font.pixelSize: 13
                        }

                        Singletons.Icon {
                            visible: modelData.pairing
                            source: generalConfigs.icons.bluetooth.pairing
                            size: 16
                            color: Singletons.MatugenTheme.surfaceText
                        }

                        Singletons.Icon {
                            visible: modelData.paired
                            source: generalConfigs.icons.bluetooth.paired
                            size: 16
                            color: Singletons.MatugenTheme.surfaceText
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
