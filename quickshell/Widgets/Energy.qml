import QtQuick
import Quickshell
import QtQuick.Layouts
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "../FontLoaders" as FontLoaders
import "PopUpContent" as PopUpContent

Rectangle {
    id: energyBtn

    property bool hovered: false

    border.color: hovered ? Singletons.Theme.accentSoft : Singletons.Theme.darkBase
    border.width: 2

    color: hovered ? Singletons.Theme.darkBase : Singletons.Theme.lightBackground
    radius: 6

    implicitHeight: Singletons.Theme.topBarItemHeight
    implicitWidth: batteryIcon.implicitWidth +
                   chargingIcon.implicitWidth +
                   Singletons.Theme.topBarItemHorizontalPadding * 2

    anchors.verticalCenter: parent.verticalCenter

    property string batteryState: Managers.EnergyManager.stateString
    property bool charging:
        batteryState == "Charging" || batteryState == "Fully Charged" ?
            true : false

    Row {
        anchors.centerIn: parent
        spacing: 4

        Singletons.Icon {
            id: batteryIcon
            source: {
                let pct = Managers.EnergyManager.percentageInt
                if (pct < 5)  return Singletons.Theme.iconBatteryEmpty
                if (pct < 15) return Singletons.Theme.iconBatteryLow
                if (pct < 50) return Singletons.Theme.iconBatteryMedium
                return Singletons.Theme.iconBatteryFull
            }
            size: Singletons.Theme.iconDefaultSize
            antialiasing: true
            color:
                hovered ?
                    Singletons.Theme.accentSoft :
                    Singletons.Theme.darkBase
        }

        Singletons.Icon {
            id: chargingIcon
            visible: charging
            source: Singletons.Theme.iconBatteryCharging
            size: charging ? Singletons.Theme.iconDefaultSize : 0
            color:
                hovered ?
                    Singletons.Theme.accentSoft :
                    Singletons.Theme.darkBase
        }

    }

    PopupWindow {
        id: energyPopup
        anchor.item: energyBtn
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.margins.top: 35
        implicitWidth: energyContent.width
        implicitHeight: energyContent.height
        visible: false
        color: "transparent"

        PopUpContent.EnergyPopup {
            id: energyContent
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
            Managers.PopupManager.toggle(energyPopup)
        }
    }
}
