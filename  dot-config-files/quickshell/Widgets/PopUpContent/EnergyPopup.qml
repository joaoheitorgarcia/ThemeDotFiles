import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
    id: energyContent
    implicitWidth: 350
    implicitHeight: 150

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 12
        color: Singletons.MatugenTheme.surfaceContainer
        border.color: Singletons.MatugenTheme.outline
        border.width: 1

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
                color: Singletons.MatugenTheme.surfaceText
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
                            color: Singletons.MatugenTheme.surfaceText
                            source: {
                                let pct = Managers.EnergyManager.percentageInt
                                if (pct < 5)  return generalConfigs.icons.battery.empty
                                if (pct < 15) return generalConfigs.icons.battery.low
                                if (pct < 50) return generalConfigs.icons.battery.medium
                                return generalConfigs.icons.battery.full
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
                            color: Singletons.MatugenTheme.surfaceText
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: Managers.EnergyManager.stateString
                            color: Singletons.MatugenTheme.surfaceVariantText
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
                            color: Singletons.MatugenTheme.surfaceVariant
                            border.color: Singletons.MatugenTheme.outline
                            border.width: 1

                            Rectangle {
                                width: Math.max(
                                           0,
                                           Math.min(1, Managers.EnergyManager.percentageInt / 100.0)
                                       ) * parent.width
                                height: parent.height
                                radius: 4
                                color: Singletons.MatugenTheme.secondary
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
                            color: Singletons.MatugenTheme.surfaceVariantText
                            font.pixelSize: 12
                        }

                        Text {
                            visible: Managers.EnergyManager.stateString === "Discharging"
                                     && Managers.EnergyManager.timeToEmptyText !== ""
                            text: "Time Remaining: " + Managers.EnergyManager.timeToEmptyText
                            color: Singletons.MatugenTheme.surfaceVariantText
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
                    color: Singletons.MatugenTheme.surfaceText
                    font.pixelSize: 12
                }

                Row {
                    spacing: 6

                    // Saver
                    Text {
                        text: "Saver"
                        font.pixelSize: 11
                        color: Managers.EnergyManager.powerProfileLabel === "Power Saver"
                               ? Singletons.MatugenTheme.surfaceText
                               : Singletons.MatugenTheme.surfaceVariantText
                        opacity: Managers.EnergyManager.powerProfileLabel === "Power Saver" ? 1.0 : 0.8

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
                        color: Managers.EnergyManager.powerProfileLabel === "Balanced"
                               ? Singletons.MatugenTheme.surfaceText
                               : Singletons.MatugenTheme.surfaceVariantText
                        opacity: Managers.EnergyManager.powerProfileLabel === "Balanced" ? 1.0 : 0.8

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
                        color: Managers.EnergyManager.powerProfileLabel === "Performance"
                               ? Singletons.MatugenTheme.surfaceText
                               : Singletons.MatugenTheme.surfaceVariantText
                        visible: Managers.EnergyManager.hasPerformanceProfile
                        opacity: Managers.EnergyManager.powerProfileLabel === "Performance" ? 1.0 : 0.8

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
