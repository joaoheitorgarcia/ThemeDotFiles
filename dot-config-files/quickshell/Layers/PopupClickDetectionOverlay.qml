import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

PanelWindow {
    required property var modelData
    screen: modelData

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    color: "transparent"
    implicitWidth: screen.width
    implicitHeight: screen.height - generalConfigs.topBar.height

    visible: Managers.PopupManager.hasOpenPopups()

    MouseArea {
        anchors.fill: parent
        onClicked: Managers.PopupManager.closeAll()
    }
}
