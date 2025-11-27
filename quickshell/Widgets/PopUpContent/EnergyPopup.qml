import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
    id: energyContent
    implicitWidth: 350
    implicitHeight: 150

    property color batteryFillColor: {
        const pct = Managers.EnergyManager.percentageInt
        const state = Managers.EnergyManager.stateString

        if (state === "Charging")
            return Singletons.Theme.hightEnergy

        if (pct <= 15)
            return Singletons.Theme.lowEnergy
        if (pct <= 50)
            return Singletons.Theme.mediumEnergy

        return Singletons.Theme.hightEnergy
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // ───────────────────────────
            // HEADER
            // ───────────────────────────
            Text {
                text: "Energy"
                font.bold: true
                font.pixelSize: 16
                color: Singletons.Theme.darkBase
                Layout.alignment: Qt.AlignLeft
            }

            // ───────────────────────────
            // STATUS + BAR + TIME GROUP
            // ───────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                // MAIN STATUS ROW
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28

                        Singletons.Icon {
                            id: batteryIcon
                            anchors.fill: parent
                            size: 24
                            color: Singletons.Theme.darkBase
                            source: {
                                let pct = Managers.EnergyManager.percentageInt
                                if (pct < 5)  return Singletons.Theme.iconBatteryEmpty
                                if (pct < 15) return Singletons.Theme.iconBatteryLow
                                if (pct < 50) return Singletons.Theme.iconBatteryMedium
                                return Singletons.Theme.iconBatteryFull
                            }
                        }
                    }
                    // ───────────────────────────
                    // PERCENTAGE + STATE INLINE
                    // ───────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Text {
                            text: Managers.EnergyManager.percentageInt + "%"
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: Managers.EnergyManager.stateString
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                // ───────────
                // BAR + TIME
                // ───────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // ───────────
                    // BATTERY BAR
                    // ───────────
                    Item {
                        Layout.fillWidth: true

                        Rectangle {
                            id: batteryTrack
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 8
                            radius: 4
                            color: Singletons.Theme.accentSoft

                            Rectangle {
                                width: Math.max(
                                           0,
                                           Math.min(1, Managers.EnergyManager.percentageInt / 100.0)
                                       ) * parent.width
                                height: parent.height
                                radius: 4
                                color: energyContent.batteryFillColor
                            }
                        }
                    }

                    // ───────────
                    // TIME INFO
                    // ───────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            visible: Managers.EnergyManager.stateString === "Charging"
                                     && Managers.EnergyManager.timeToFullText !== ""
                            text: "Time to Full: " + Managers.EnergyManager.timeToFullText
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 12
                        }

                        Text {
                            visible: Managers.EnergyManager.stateString === "Discharging"
                                     && Managers.EnergyManager.timeToEmptyText !== ""
                            text: "Time Remaining: " + Managers.EnergyManager.timeToEmptyText
                            color: Singletons.Theme.darkBase
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ───────────────────────────
            // POWER MODE SELECTOR
            // ───────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Power Mode:"
                    color: Singletons.Theme.darkBase
                    font.pixelSize: 12
                }

                Row {
                    spacing: 6

                    // Saver
                    Text {
                        text: "Saver"
                        font.pixelSize: 11
                        color: Singletons.Theme.darkBase
                        opacity: Managers.EnergyManager.powerProfileLabel === "Power Saver" ? 1.0 : 0.6

                        MouseArea {
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            onClicked: Managers.EnergyManager.setPowerSaver()
                        }
                    }

                    // Balanced
                    Text {
                        text: "Balanced"
                        font.pixelSize: 11
                        color: Singletons.Theme.darkBase
                        opacity: Managers.EnergyManager.powerProfileLabel === "Balanced" ? 1.0 : 0.6

                        MouseArea {
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            onClicked: Managers.EnergyManager.setBalanced()
                        }
                    }

                    // Performance
                    Text {
                        text: "Performance"
                        font.pixelSize: 11
                        color: Singletons.Theme.darkBase
                        visible: Managers.EnergyManager.hasPerformanceProfile
                        opacity: Managers.EnergyManager.powerProfileLabel === "Performance" ? 1.0 : 0.6

                        MouseArea {
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            enabled: Managers.EnergyManager.hasPerformanceProfile
                            onClicked: Managers.EnergyManager.setPerformance()
                        }
                    }
                }
            }

        }
    }
}
