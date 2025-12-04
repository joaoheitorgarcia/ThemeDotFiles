import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../Singletons" as Singletons


//TODO Make Critical notifications not have a timer
//add actions if notification has those

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
        screen: Quickshell.screens && Quickshell.screens.length > 0
                ? Quickshell.screens[0]
                : null

        property real maxHeight: screen ? screen.height / 3 : 400
        property var notifTimers: ({})

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

        ListModel {
            id: notifModel
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            onEntered: {
                for (var id in notifWindow.notifTimers) {
                    var t = notifWindow.notifTimers[id]
                    if (t) t.stop()
                }
            }

            onExited: {
                for (var id in notifWindow.notifTimers) {
                    var t = notifWindow.notifTimers[id]
                    if (t) t.start()
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

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: 12
                    color: Singletons.Theme.lightBackground
                    border.color: Singletons.Theme.darkBase
                    border.width: 2

                    property int hiddenCount: Math.max(
                        0,
                        notifModel.count - Singletons.Theme.maxVisibleNotifications
                    )

                    visible: hiddenCount > 0

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "+" +
                                  parent.parent.hiddenCount +
                                  " more notification" +
                                  (parent.parent.hiddenCount > 1 ? "s" : "")
                            font.pixelSize: 14
                            font.bold: false
                            color: Singletons.Theme.darkBase
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notifWindow.clearAllNotifications()
                        }
                    }
                }

                Repeater {
                    model: notifModel

                    delegate: Item {
                        width: notifColumn.width
                        height: notifBg.height
                        opacity: model.opacity || 1
                        scale: model.scale || 1
                        visible: index < Singletons.Theme.maxVisibleNotifications

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
                                        visible: !!model.icon
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
                                            color: Singletons.Theme.darkBase
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Singletons.Theme.darkBase
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
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    notifWindow.closeNotification(model.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        function indexOfNotification(id) {
            for (var i = 0; i < notifModel.count; i++) {
                if (notifModel.get(i).id === id)
                    return i
            }
            return -1
        }

        function closeNotification(id) {
            var timer = notifTimers[id]
            if (timer) {
                timer.stop()
                timer.destroy()
                delete notifTimers[id]
            }

            var idx = indexOfNotification(id)
            if (idx === -1)
                return

            notifModel.setProperty(idx, "opacity", 0)
            notifModel.setProperty(idx, "scale", 0.95)

            var removeTimer = Qt.createQmlObject(
                'import QtQuick; Timer { interval: 250; running: true; repeat: false }',
                notifWindow
            )

            removeTimer.triggered.connect(function() {
                var idx2 = indexOfNotification(id)
                if (idx2 !== -1) {
                    notifModel.remove(idx2)
                }

                removeTimer.destroy()

                if (notifModel.count === 0)
                    notifWindow.visible = false
            })
        }

        function clearAllNotifications() {
            for (var id in notifTimers) {
                var t = notifTimers[id]
                if (t) t.destroy()
            }
            notifTimers = ({})
            notifModel.clear()
            notifWindow.visible = false
        }

        function addNotification(n) {
            var notifId = Date.now() + Math.random()

            notifModel.append({
                id: notifId,
                icon: n.appIcon || n.image,
                appName: n.appName,
                summary: n.summary,
                body: n.body,
                opacity: 0,
                scale: 0.95
            })

            var index = notifModel.count - 1

            notifModel.setProperty(index, "opacity", 1)
            notifModel.setProperty(index, "scale", 1)

            var timer = Qt.createQmlObject(
                'import QtQuick; Timer { interval: 5000; running: true; repeat: false }',
                notifWindow
            )

            notifTimers[notifId] = timer

            timer.triggered.connect(function() {
                notifWindow.closeNotification(notifId)
            })

            if (!notifWindow.visible)
                notifWindow.visible = true
        }
    }

    NotificationServer {
        onNotification: function(n) {
            console.log("Notification received:", n.appName, '->', n.summary, n.body)
            notifWindow.addNotification(n)
        }
    }
}
