import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "PopUpContent" as PopUpContent

Rectangle {
    id: wifiBtn

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    border.color:
        hovered ?
            Singletons.MatugenTheme.surfaceVariant :
            Singletons.MatugenTheme.surfaceVariantText
    border.width: 2

    color:
        hovered ?
            Singletons.MatugenTheme.surfaceVariantText :
            Singletons.MatugenTheme.surfaceText
    radius: 8

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    implicitHeight: generalConfigs.topBar.itemHeight
    implicitWidth: (
        iconItem.implicitWidth +
        generalConfigs.topBar.itemHorizontalPadding * 2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Singletons.Icon {
        id: iconItem
        source: Managers.NetworkManager.wiredConnected
                ? generalConfigs.icons.network.wired
                : Managers.NetworkManager.wifiConnected
                  ? (Managers.NetworkManager.strength >= 60
                     ? generalConfigs.icons.network.wifiStrength3
                     : Managers.NetworkManager.strength >= 40
                       ? generalConfigs.icons.network.wifiStrength2
                       : Managers.NetworkManager.strength >= 20
                         ? generalConfigs.icons.network.wifiStrength1
                         : generalConfigs.icons.network.wifiStrength0)
                  : generalConfigs.icons.network.wifiStrengthSlash

        size: generalConfigs.icons.defaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.MatugenTheme.surfaceVariant :
                Singletons.MatugenTheme.surfaceContainer
    }

    PopupWindow {
        id: networkPopup
        anchor.item: wifiBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: networkContent.width
        implicitHeight: networkContent.height
        visible: false
        color: "transparent"

        PopUpContent.NetworkPopup {
            id: networkContent
        }

        Component.onCompleted: {
            Managers.PopupManager.register(this)
            Managers.PipewireManager.refreshVolume()
        }

        Component.onDestruction: {
            Managers.PopupManager.unregister(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        hoverEnabled: true
        onEntered: hovered = true
        onExited: hovered = false
        onClicked: Managers.PopupManager.toggle(networkPopup)
    }
}
