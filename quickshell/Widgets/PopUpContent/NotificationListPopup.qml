import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../Singletons" as Singletons

Item {
    id: notificationListContent
    implicitWidth: 320
    implicitHeight: 300

    ListModel{
        id: unTrackedNotifications
    }

    Connections {
        target: NotificationServer{
            onNotification:(n)=>{
                unTrackedNotifications.append(n)
            }
        }
    }

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
            anchors.bottomMargin: 5

            Text{
                text: "Notification History"
                font.bold: true
                font.pixelSize: 16
                color: Singletons.Theme.darkBase
            }

            ListView {
                id: notificationhistoryList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: true
                model: unTrackedNotifications

                ScrollBar.vertical: ScrollBar {
                    policy: notificationhistoryList.contentHeight > notificationhistoryList.height ?
                                ScrollBar.AlwaysOn :
                                ScrollBar.AlwaysOff
                }

                delegate: Rectangle {
                    id: listOption
                    width: notificationhistoryList.width
                    height: 50
                    radius: 4
                    color: hovered ? Singletons.Theme.accentSoftYellow : "transparent"

                    property bool hovered: false

                    Row {
                        width: parent.width
                        spacing: 12

                        Singletons.Icon {
                            visible: !!model.appIcon || !!model.image
                            source: model.appIcon || model.image
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

                    Singletons.Icon {
                        visible: listOption.hovered
                        source: Singletons.Theme.iconClose
                        color: Singletons.Theme.darkBase
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false

                        onClicked: {
                            var idx = index
                            unTrackedNotifications.remove(idx)
                        }
                    }
                }

                Text {
                    text: 'No new notification'
                    width: parent.width
                    font.pixelSize: 11
                    color: Singletons.Theme.darkBase
                    visible: unTrackedNotifications.count === 0
                }
            }


        }
    }
}
