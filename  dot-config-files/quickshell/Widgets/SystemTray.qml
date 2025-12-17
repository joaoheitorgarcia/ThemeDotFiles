import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import Quickshell.Services.SystemTray
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../Singletons" as Singletons

Rectangle {
    id: trayBar

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    radius: 6
    color: "transparent"
    implicitHeight: generalConfigs.topBar.itemHeight
    implicitWidth: trayLayout.implicitWidth

    property var window

    property int iconSize: 24
    property int itemSize: 28
    property color hoverColor: Singletons.MatugenTheme.surfaceVariantText
    property color pressColor: Singletons.MatugenTheme.surfaceText
    property int cornerRadius: 6

    RowLayout {
        id: trayLayout
        anchors.fill: parent

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayItemWrapper
                Layout.preferredWidth: itemSize
                Layout.preferredHeight: itemSize
                radius: cornerRadius
                color: {
                    if (trayMouseArea.pressed) return pressColor
                    if (trayMouseArea.containsMouse) return hoverColor
                    return "transparent"
                }

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: iconSize
                    height: iconSize
                    source: Quickshell.iconPath(modelData.icon, true) !== "" ?
                                Quickshell.iconPath(modelData.icon, true) :
                                modelData.icon
                    smooth: true
                    antialiasing: true
                }

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            var pos = trayIcon.mapToItem(
                                trayBar.window.contentItem,
                                trayIcon.width / 2,
                                trayIcon.height
                            )
                            modelData.display(trayBar.window, pos.x, pos.y)
                        }
                    }

                    onPressedChanged: {
                        trayItemWrapper.scale = pressed ? 0.92 : 1.0
                    }
                }

                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }
            }
        }
    }
}
