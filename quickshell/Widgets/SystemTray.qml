import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import Quickshell.Services.SystemTray
import "../Singletons" as Singletons

//TODO fix icon menu and filter
Rectangle {
    id: trayBar
    radius: 6

    color: "transparent"
    implicitHeight: Singletons.Theme.topBarItemHeight
    implicitWidth: trayLayout.implicitWidth

    property var window

    property int iconSize: 24
    property int itemSize: 28
    property color hoverColor: Singletons.Theme.darkBase
    property color pressColor: Singletons.Theme.darkBase
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

                property color iconColor: trayMouseArea.containsMouse ?
                                              Singletons.Theme.lightBackground :
                                              Singletons.Theme.darkBase

                //set true for original icon colors
                property bool colorizeIcons: false

                property bool isIconLight: (
                    modelData.icon.toString().match(/symbolic|light|white/i) !== null
                )

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: iconSize
                    height: iconSize
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    visible: !colorizeIcons
                    smooth: true
                    antialiasing: true
                }

                MultiEffect {
                    anchors.centerIn: parent
                    width: iconSize
                    height: iconSize
                    source: trayIcon
                    colorization: colorizeIcons ? 1.0 : 0
                    colorizationColor: iconColor

                    smooth: true
                    antialiasing: true

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            var pos = trayIcon.mapToGlobal(trayIcon.width / 2, trayIcon.height)
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
