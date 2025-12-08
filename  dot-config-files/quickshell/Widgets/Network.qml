import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "../FontLoaders" as FontLoaders
import "PopUpContent" as PopUpContent

Rectangle{
    id: wifiBtn

    border.color:
        hovered ?
            Singletons.Theme.accentSoft :
            Singletons.Theme.darkBase
    border.width: 2

    color:
        hovered ?
            Singletons.Theme.darkBase :
            Singletons.Theme.lightBackground
    radius: 6

    implicitHeight: Singletons.Theme.topBarItemHeight
    implicitWidth: (
        iconItem.implicitWidth +
        Singletons.Theme.topBarItemHorizontalPadding *
        2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Singletons.Icon {
        id: iconItem
        source: Managers.NetworkManager.wiredConnected
                ? Singletons.Theme.iconWired
                : Managers.NetworkManager.wifiConnected
                  ? (Managers.NetworkManager.strength >= 60
                     ? Singletons.Theme.iconWifiStrength3
                     : Managers.NetworkManager.strength >= 40
                       ? Singletons.Theme.iconWifiStrength2
                       : Managers.NetworkManager.strength >= 20
                         ? Singletons.Theme.iconWifiStrength1
                         : Singletons.Theme.iconWifiStrength0)
                  : Singletons.Theme.iconWifiStrengthSlash

        size: Singletons.Theme.iconDefaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.Theme.accentSoft :
                Singletons.Theme.darkBase
    }

    PopupWindow {
        id: networkPopup
        anchor.item: wifiBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: networkContent.width
        implicitHeight: networkContent.height
        visible: false
        color:"transparent"

        PopUpContent.NetworkPopup{
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
