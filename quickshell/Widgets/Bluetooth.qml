import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "../FontLoaders" as FontLoaders
import "PopUpContent" as PopUpContent

Rectangle{
    id: bluetoothBtn

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
        source: Singletons.Theme.iconBluetooth
        size: Singletons.Theme.iconDefaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.Theme.accentSoft :
                Singletons.Theme.darkBase
    }

    PopupWindow {
        id: bluetoothPopup
        anchor.item: bluetoothBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: bluetoothContent.width
        implicitHeight: bluetoothContent.height
        visible: false
        color:"transparent"

        PopUpContent.BluetoothPopup{
            id: bluetoothContent
        }

        Component.onCompleted: {
            Managers.PopupManager.register(this)
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
        onClicked: Managers.PopupManager.toggle(bluetoothPopup)
    }
}
