import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

PanelWindow {
    required property var modelData
    screen: modelData

    color: "transparent"
    implicitWidth: screen.width
    implicitHeight: screen.height - Singletons.Theme.topBarHeight

    visible: Managers.PopupManager.hasOpenPopups()

    MouseArea {
        anchors.fill: parent
        onClicked: Managers.PopupManager.closeAll()
    }
}
