import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "PopUpContent" as PopUpContent
import "../Singletons/Managers" as Managers

Rectangle {
    id: clockBtn

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    border.color:
        hovered ?
            Singletons.MatugenTheme.surfaceVariantText :
            Singletons.MatugenTheme.surfaceText
    border.width: 2

    radius: 8
    color:
        hovered ?
            Singletons.MatugenTheme.surfaceContainerHighest :
            Singletons.MatugenTheme.surfaceContainer

    implicitHeight: generalConfigs.topBar.itemHeight
    implicitWidth: (
        textItem.implicitWidth +
        generalConfigs.topBar.itemHorizontalPadding * 2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: textItem
        anchors.centerIn: parent

        color:
            hovered ?
                Singletons.MatugenTheme.surfaceVariantText :
                Singletons.MatugenTheme.surfaceText
        font.pixelSize: generalConfigs.font.titleSize
        font.family: Singletons.FontLoader.font
        text: Singletons.Time.time
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    PopupWindow {
        id: calendarPopup
        anchor.item: clockBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: calendarContent.width
        implicitHeight: calendarContent.height
        visible: false
        color: "transparent"

        PopUpContent.CalendarPopup {
            id: calendarContent
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
        onClicked: Managers.PopupManager.toggle(calendarPopup)
    }
}
