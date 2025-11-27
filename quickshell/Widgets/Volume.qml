import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "../FontLoaders" as FontLoaders
import "PopUpContent" as PopUpContent

Rectangle{
    id: soundBtn

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
        source: {
            let vol = Managers.PipewireManager.volume
            if (vol === 0) return Singletons.Theme.iconVolumeMute
            if (vol < 0.33) return Singletons.Theme.iconVolumeLow
            if (vol < 0.66) return Singletons.Theme.iconVolumeMedium
            return Singletons.Theme.iconVolumeHigh
        }
        size: Singletons.Theme.iconDefaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.Theme.accentSoft :
                Singletons.Theme.darkBase
    }

    PopupWindow {
        id: volPopup
        anchor.item: soundBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: volumeContent.width
        implicitHeight: volumeContent.height
        visible: false
        color:"transparent"

        PopUpContent.VolumePopup{
            id: volumeContent
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
        onClicked: {
            Managers.PopupManager.toggle(volPopup)
            Managers.PipewireManager.refreshVolume()
        }
    }
}
