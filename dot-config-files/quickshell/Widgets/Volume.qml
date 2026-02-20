import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "PopUpContent" as PopUpContent

Rectangle {
    id: soundBtn

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    border.color:
        hovered ?
            Singletons.MatugenTheme.surfaceVariantText :
            Singletons.MatugenTheme.surfaceText
    border.width: 2

    color:
        hovered ?
            Singletons.MatugenTheme.surfaceContainerHighest :
            Singletons.MatugenTheme.surfaceContainer
    radius: 8

    implicitHeight: generalConfigs.topBar.itemHeight
    implicitWidth: (
        iconItem.implicitWidth +
        generalConfigs.topBar.itemHorizontalPadding * 2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Singletons.Icon {
        id: iconItem
        source: {
            let vol = Managers.PipewireManager.volume
            if (vol === 0) return generalConfigs.icons.volume.mute
            if (vol < 0.33) return generalConfigs.icons.volume.low
            if (vol < 0.66) return generalConfigs.icons.volume.medium
            return generalConfigs.icons.volume.high
        }
        size: generalConfigs.icons.defaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.MatugenTheme.surfaceVariantText :
                Singletons.MatugenTheme.surfaceText
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    PopupWindow {
        id: volPopup
        anchor.item: soundBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: volumeContent.width
        implicitHeight: volumeContent.height
        visible: false
        color: "transparent"

        PopUpContent.VolumePopup {
            id: volumeContent
        }

        Component.onCompleted: {
            Managers.PopupManager.register(this)
            Managers.PipewireManager.refresh()
        }

        Component.onDestruction: {
            Managers.PopupManager.unregister(this)
        }

        onVisibleChanged: if (visible) Managers.PipewireManager.refresh()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        hoverEnabled: true
        onEntered: hovered = true
        onExited: hovered = false
        onClicked: {
            Managers.PopupManager.toggle(volPopup)
            Managers.PipewireManager.refresh()
        }
    }
}
