import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "PopUpContent" as PopUpContent

Rectangle {
    id: powerBtn

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

    implicitHeight: generalConfigs.topBar.itemHeight
    implicitWidth: (
        iconItem.implicitWidth +
        generalConfigs.topBar.itemHorizontalPadding * 2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Singletons.Icon {
        id: iconItem
        source: generalConfigs.icons.powerMenu.shutdown
        size: generalConfigs.icons.defaultSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        color:
            hovered ?
                Singletons.MatugenTheme.surfaceVariant :
                Singletons.MatugenTheme.surfaceContainer
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    PopupWindow {
        id: powerMenuPopup
        anchor.item: powerBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: powerMenuContent.width
        implicitHeight: powerMenuContent.height
        visible: false
        color: "transparent"

        PopUpContent.PowerMenuPopup {
            id: powerMenuContent
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
        onClicked: Managers.PopupManager.toggle(powerMenuPopup)
    }
}
