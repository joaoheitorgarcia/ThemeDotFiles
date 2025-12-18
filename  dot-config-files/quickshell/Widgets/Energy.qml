import QtQuick
import Quickshell
import QtQuick.Layouts
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers
import "PopUpContent" as PopUpContent

Rectangle {
    id: energyBtn

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    property bool hovered: false

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
    implicitWidth: batteryIcon.implicitWidth +
                   chargingIcon.implicitWidth +
                   generalConfigs.topBar.itemHorizontalPadding * 2

    anchors.verticalCenter: parent.verticalCenter

    property string batteryState: Managers.EnergyManager.stateString
    property string batteryPercentage: Managers.EnergyManager.percentageInt
    property bool charging:
        batteryState == "Charging" || batteryState == "Fully Charged" ?
            true : false

    Row {
        anchors.centerIn: parent
        spacing: 4

        Singletons.Icon {
            id: batteryIcon
            source: {
                if (batteryPercentage < 5)  return generalConfigs.icons.battery.empty
                if (batteryPercentage < 15) return generalConfigs.icons.battery.low
                if (batteryPercentage < 50) return generalConfigs.icons.battery.medium
                return generalConfigs.icons.battery.full
            }
            size: generalConfigs.icons.defaultSize
            antialiasing: true
            color: {
                if (hovered) {
                    return Singletons.MatugenTheme.surfaceVariantText
                } else {
                    if (batteryPercentage <= 15 && batteryState !== "Charging")
                        return Singletons.MatugenTheme.errorColor
                    return Singletons.MatugenTheme.surfaceText
                }
            }
        }

        Singletons.Icon {
            id: chargingIcon
            visible: charging
            source: generalConfigs.icons.battery.charging
            size: charging ? generalConfigs.icons.defaultSize : 0
            color:
                hovered ?
                    Singletons.MatugenTheme.surfaceVariantText :
                    Singletons.MatugenTheme.surfaceText
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

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
}
