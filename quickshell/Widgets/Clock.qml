import QtQuick
import Quickshell
import "../Singletons" as Singletons
import "../FontLoaders" as FontLoaders
import "PopUpContent" as PopUpContent
import "../Singletons/Managers" as Managers

Rectangle{

    border.color:
        hovered ?
            Singletons.Theme.accentSoft :
            Singletons.Theme.darkBase
    border.width: 2

    radius: 6
    color:
        hovered ?
            Singletons.Theme.darkBase :
            Singletons.Theme.lightBackground

    implicitHeight: Singletons.Theme.topBarItemHeight
    implicitWidth: (
        textItem.implicitWidth +
        Singletons.Theme.topBarItemHorizontalPadding *
        2
    )

    property bool hovered: false
    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: textItem
        anchors.centerIn: parent

        color:
            hovered ?
                Singletons.Theme.accentSoft :
                Singletons.Theme.darkBase
        font.pixelSize: Singletons.Theme.defaultFontSize
        font.family: Singletons.Theme.font
        text: Singletons.Time.time
    }

    PopupWindow {
        id: calendarPopup
        anchor.item: textItem
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: calendarContent.width
        implicitHeight: calendarContent.height
        visible: false
        color:"transparent"

        PopUpContent.CalendarPopup{
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




