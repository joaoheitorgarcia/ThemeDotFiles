import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../Singletons" as Singletons

Item {
    id: notifications

    PanelWindow {
        id: notifWindow
        visible: false
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

        property real maxHeight: screen ? screen.height / 3 : 400

        anchors {
            top: true
            right: true
            left: false
            bottom: false
        }

        margins {
            top: 10
            right: 10
        }

        implicitWidth: 400
        implicitHeight: Math.min(notifColumn.implicitHeight + 20, maxHeight)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: {
                // Stop all hide timers when hovering
                for (var i = 0; i < notifModel.count; i++) {
                    var item = notifModel.get(i)
                    if (item.timer) item.timer.stop()
                }
            }
            onExited: {
                // Restart all hide timers when leaving
                for (var i = 0; i < notifModel.count; i++) {
                    var item = notifModel.get(i)
                    if (item.timer) item.timer.restart()
                }
            }
        }

        Item {
            id: container
            anchors.fill: parent
            anchors.margins: 10

            Column {
                id: notifColumn
                anchors.right: parent.right
                anchors.top: parent.top
                width: 300
                spacing: 10

                // Counter badge for hidden notifications
                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 12
                    color: Singletons.Theme.lightBackground
                    border.color: Singletons.Theme.darkBase
                    border.width: 2
                    visible: hiddenCount > 0

                    property int hiddenCount: Math.max(0, notifModel.count - notifWindow.maxVisibleNotifications)

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "+" +
                                  parent.parent.hiddenCount +
                                  " more notification" + (parent.parent.hiddenCount > 1 ? "s" : "")
                            font.pixelSize: 14
                            font.bold: false
                            color: Singletons.Theme.darkBase
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            while (notifModel.count > 0) {
                                removeNotification(0)
                            }
                        }
                    }
                }

                Repeater {
                    model: ListModel { id: notifModel }

                    delegate: Item {
                        width: notifColumn.width
                        height: notifBg.height
                        opacity: model.opacity || 1
                        scale: model.scale || 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.2
                            }
                        }

                        Rectangle {
                            id: notifBg
                            width: parent.width
                            height: notifContent.implicitHeight + 28
                            radius: 12
                            color: Singletons.Theme.lightBackground
                            border.color: Singletons.Theme.darkBase
                            border.width: 2

                            Column {
                                id: notifContent
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 12

                                    Singletons.Icon {
                                        source: model.icon || ""
                                        color: Singletons.Theme.darkBase
                                        width: 32
                                        height: 32
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Column {
                                        width: parent.width - 44
                                        spacing: 4

                                        Text {
                                            text: model.summary || ""
                                            width: parent.width
                                            font.bold: true
                                            font.pixelSize: 14
                                            color: Singletons.Theme.darkBase
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: model.appName || ""
                                            width: parent.width
                                            font.pixelSize: 11
                                            color: Qt.rgba(
                                                Singletons.Theme.darkBase.r,
                                                Singletons.Theme.darkBase.g,
                                                Singletons.Theme.darkBase.b,
                                                0.6
                                            )
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(
                                        Singletons.Theme.darkBase.r,
                                        Singletons.Theme.darkBase.g,
                                        Singletons.Theme.darkBase.b,
                                        0.1
                                    )
                                    visible: model.body !== ""
                                }

                                Text {
                                    text: model.body || ""
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    font.pixelSize: 13
                                    color: Singletons.Theme.darkBase
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            MouseArea {
                                id: closeButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notifWindow.removeNotification(index)
                            }
                        }
                    }
                }
            }
        }

        property int maxVisibleNotifications: 0

        function calculateMaxVisible() {
            var availableHeight = maxHeight - 40
            var notificationHeight = 100
            var spacing = 10
            maxVisibleNotifications = Math.floor(availableHeight / (notificationHeight + spacing))
            if (maxVisibleNotifications < 1) maxVisibleNotifications = 1
        }

        Component.onCompleted: calculateMaxVisible()

        function addNotification(icon, appName, summary, body) {

            // Create auto-hide timer
            var timer = Qt.createQmlObject(
                'import QtQuick; Timer { interval: 5000; running: true; repeat: false }',
                notifWindow
            )

            var index = notifModel.count
            timer.triggered.connect(function() {
                removeNotification(index)
            })

            // Add to model
            notifModel.append({
                icon: icon || "",
                appName: appName || "",
                summary: summary || "Notification",
                body: body || "",
                opacity: 0,
                scale: 0.95,
                timer: timer
            })

            // Animate in
            notifModel.setProperty(index, "opacity", 1)
            notifModel.setProperty(index, "scale", 1)

            // Show window if hidden
            if (!notifWindow.visible) {
                notifWindow.visible = true
            }
        }

        function removeNotification(index) {
            if (index < 0 || index >= notifModel.count) return

            var item = notifModel.get(index)
            if (item.timer) {
                item.timer.stop()
                item.timer.destroy()
            }

            notifModel.setProperty(index, "opacity", 0)
            notifModel.setProperty(index, "scale", 0.95)

            var removeTimer = Qt.createQmlObject(
                'import QtQuick; Timer { interval: 300; running: true; repeat: false }',
                notifWindow
            )
            removeTimer.triggered.connect(function() {
                notifModel.remove(index)
                removeTimer.destroy()

                if (notifModel.count === 0) {
                    notifWindow.visible = false
                }
            })
        }
    }

    NotificationServer {
        onNotification: function(n) {
            console.log("Notification received:", n.summary, n.body)
            notifWindow.addNotification(
                n.appIcon,
                n.appName,
                n.summary,
                n.body
            )
        }
    }
}
