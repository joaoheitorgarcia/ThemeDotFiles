import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../Widgets" as Widgets
import "../Singletons" as Singletons

PanelWindow {
    required property var modelData
    screen: modelData

    id: topBar

    anchors {
        left: true
        right: true
        top: true
    }

    implicitHeight: Singletons.Theme.topBarHeight
    color: "transparent"

    aboveWindows: false
    exclusiveZone: height

    RowLayout {
        anchors.fill: parent
        spacing: 10
        anchors.rightMargin: 5

        Row{
            spacing: 5
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            Widgets.SystemTray {
                window: topBar
            }
            Widgets.Clock {}
            Widgets.Bluetooth{}
            Widgets.Network {}
            Widgets.Volume {}
            Widgets.Energy{}
            Widgets.Power {}

            //TODO notification queue
        }
    }
}
