import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

//TODO
//fiz searchField
//fix register race condition on pop up detection overlay

PanelWindow {
    id: launcher
    visible: false
    color: "transparent"
    focusable: true

    exclusiveZone: 0
    aboveWindows: true

    implicitWidth: 450
    implicitHeight: 400

    Component.onCompleted:{
        Managers.PopupManager.register(this)
    }

    Component.onDestruction: {
        Managers.PopupManager.unregister(this)
    }

    property var appList: DesktopEntries.applications

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            TextField {
                id: searchField
                placeholderText: "Search apps…"
                Layout.fillWidth: true
                font.pixelSize: 16
                onTextChanged: {
                    if (text.length > 0) {
                        launcher.appList = DesktopEntries.heuristicLookup(text)
                    } else {
                        launcher.appList = DesktopEntries.applications
                    }
                    appListView.currentIndex = 0
                }
            }

            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                clip: true
                model: launcher.appList

                currentIndex: 0
                keyNavigationWraps: true
                highlightFollowsCurrentItem: false


                delegate: Rectangle {
                    id: appListOption
                    property bool hovered: false

                    width: appListView.width
                    height: 55
                    radius: 8

                    color: (ListView.isCurrentItem || hovered)
                           ? Singletons.Theme.accentSoft
                           : "transparent"
                    border.color: (ListView.isCurrentItem || hovered)
                                  ? Singletons.Theme.darkBase
                                  : "transparent"
                    border.width: (ListView.isCurrentItem || hovered) ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Image {
                            id: appIcon
                            visible: modelData.icon !== ""
                            source: Quickshell.iconPath(modelData.icon, true) !== "" ?
                                        Quickshell.iconPath(modelData.icon, true) :
                                        "../Icons/regular/bx-window.svg"
                            sourceSize.width: 30
                            sourceSize.height: 30
                            width: 30
                            height: 30
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                        }

                        ColumnLayout {
                            width: parent.width - 30
                            spacing: 4

                            Text {
                                text: modelData ? modelData.name : "Unknown App"
                                font.pixelSize: 14
                                color: Singletons.Theme.darkBase
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }


                            Text {
                                text: modelData.genericName !== '' ? modelData.genericName: modelData.comment
                                font.pixelSize: 10
                                color: Singletons.Theme.darkBase
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            launcher.visible = false
                            modelData.execute()
                        }
                    }
                }
            }
        }

        Keys.onPressed: function (event) {
            if (!launcher.visible)
                return

            switch (event.key) {
                case Qt.Key_Up:
                    if(appListView.currentIndex >= 1){
                        appListView.decrementCurrentIndex()
                        appListOption.forceActiveFocus()
                    }
                    event.accepted = true
                    break
                case Qt.Key_Down:
                    if(appListView.currentIndex < appListView.count - 1){
                        appListView.incrementCurrentIndex()
                        appListOption.forceActiveFocus()
                    }
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (appListView.currentIndex >= 0) {
                        var entry = launcher.appList[appListView.currentIndex]
                        if (entry) {
                            launcher.visible = false
                            Managers.PopupManager.close(launcher)
                            entry.execute()
                        }
                    }
                    event.accepted = true
                    break
                case Qt.Key_Escape:
                    toggle()
                    event.accepted = true
                    break
            }

        }
    }

    function toggle() {
        Managers.PopupManager.toggle(launcher)
        if (launcher.visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
            //todo This is working weird, not working before I instanciate another popup
        }
    }
}
