import QtQuick
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

Rectangle {
    id: idleControlBtn

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()
    readonly property bool idleEnabled: Managers.IdleManager.enabled

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
        source: idleEnabled ?
            generalConfigs.icons.idleControl.enabled :
            generalConfigs.icons.idleControl.disabled
        size: generalConfigs.icons.defaultSize
        anchors.centerIn: parent
        color:
            hovered ?
                Singletons.MatugenTheme.surfaceVariantText :
                Singletons.MatugenTheme.surfaceText
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: Managers.IdleManager.initialized && !Managers.IdleManager.busy

        hoverEnabled: true
        onEntered: idleControlBtn.hovered = true
        onExited: idleControlBtn.hovered = false
        onClicked: Managers.IdleManager.toggle()
    }
}
