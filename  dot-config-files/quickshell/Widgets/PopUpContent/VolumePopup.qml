import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
    id: volumeContent
    implicitWidth: 350
    implicitHeight: 160 +
                    (Managers.PipewireManager.outputs.length * 40) +
                    (Managers.PipewireManager.inputs.length * 40)

    property real _oldVolume: 0.5

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ───────────────────────────
            // AUDIO TITLE
            // ───────────────────────────
            Text {
                text: "Audio"
                font.bold: true
                font.pixelSize: 16
                color: Singletons.Theme.darkBase
            }

            // ───────────────────────────
            // VOLUME SLIDER ROW
            // ───────────────────────────
            Item {
                width: parent.width
                height: 30

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    // ICON (Mute toggle)
                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22

                        Singletons.Icon {
                            id: volIcon
                            anchors.fill: parent
                            size: 22
                            color: Singletons.Theme.darkBase
                            source: {
                                let vol = Managers.PipewireManager.volume
                                if (vol === 0) return Singletons.Theme.iconVolumeMute
                                if (vol < 0.33) return Singletons.Theme.iconVolumeLow
                                if (vol < 0.66) return Singletons.Theme.iconVolumeMedium
                                return Singletons.Theme.iconVolumeHigh
                            }
                        }

                        MouseArea {
                            cursorShape: Qt.PointingHandCursor
                            anchors.fill: parent
                            onClicked: {
                                if (Managers.PipewireManager.volume > 0) {
                                    volumeContent._oldVolume = Managers.PipewireManager.volume
                                    Managers.PipewireManager.setVolume(0)
                                } else {
                                    Managers.PipewireManager.setVolume(volumeContent._oldVolume || 0.5)
                                }
                            }
                        }
                    }

                    // SLIDER
                    Slider {
                        id: slider
                        from: 0
                        to: 1
                        stepSize: 0.01
                        live: true

                        value: Managers.PipewireManager.volume
                        onValueChanged: {
                            // Prevent duplicate setting if value matches manager.volume
                            if (Math.abs(Managers.PipewireManager.volume - value) > 0.001) {
                                Managers.PipewireManager.setVolume(value)
                            }
                        }

                        Layout.preferredWidth: 220

                        background: Rectangle {
                            id: sliderTrack
                            x: slider.leftPadding
                            y: slider.topPadding + slider.availableHeight / 2 - height / 2
                            width: slider.availableWidth
                            height: 4
                            radius: 2
                            color: Singletons.Theme.accentSoftYellow

                            Rectangle {
                                width: slider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: Singletons.Theme.darkBase
                            }

                            MouseArea {
                                id: trackMouse
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: -10
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                drag.target: null

                                property bool isDragging: false

                                onPressed: (mouse) => {
                                    isDragging = true
                                    updateVolume(mouse.x)
                                }

                                onReleased: isDragging = false
                                onCanceled: isDragging = false

                                onPositionChanged: (mouse) => {
                                    if (isDragging) {
                                        updateVolume(mouse.x)
                                    }
                                }

                                function updateVolume(mouseX) {
                                    const handleHalf = slider.handle.width
                                    const x = mouseX - handleHalf
                                    const ratio = x / (sliderTrack.width - slider.handle.width)


                                    const clamped = Math.max(0, Math.min(1, ratio))
                                    slider.value = slider.from + (slider.to - slider.from) * clamped
                                }
                            }
                        }

                        handle: Rectangle {
                            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                            y: slider.topPadding + slider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: slider.pressed ? Singletons.Theme.accentSoftYellow : Singletons.Theme.darkBase
                            border.color: Singletons.Theme.lightBackground
                            border.width: 2
                        }
                    }

                    Text {
                        text: Math.round(Managers.PipewireManager.volume * 100) + "%"
                        color: Singletons.Theme.darkBase
                        font.pixelSize: 14
                    }
                }
            }

            // ───────────────────────────
            // OUTPUT DEVICES
            // ───────────────────────────
            Text {
                text: "Output"
                font.bold: true
                font.pixelSize: 14
                color: Singletons.Theme.darkBase
            }

            ListView {
                id: outputList
                width: parent.width
                model: Managers.PipewireManager.outputs
                height: Math.min(count * 30, 150)
                clip: true
                interactive: false

                delegate: Rectangle {
                    width: outputList.width
                    height: 30
                    color: modelData.default ? Singletons.Theme.accentSoftYellow : "transparent"

                    Text {
                        text: modelData.name || ""
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        color: Singletons.Theme.darkBase
                    }

                    MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: Managers.PipewireManager.setOutput(modelData.sinkName)
                    }
                }
            }

            // ───────────────────────────
            // INPUT DEVICES
            // ───────────────────────────
            Text {
                text: "Input"
                font.bold: true
                font.pixelSize: 14
                color: Singletons.Theme.darkBase
            }

            ListView {
                id: inputList
                width: parent.width
                model: Managers.PipewireManager.inputs
                height: Math.min(count * 30, 150)
                clip: true

                delegate: Rectangle {
                    width: inputList.width
                    height: 30
                    color: modelData.default ? Singletons.Theme.accentSoftYellow : "transparent"

                    Text {
                        text: modelData.name || ""
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        color: Singletons.Theme.darkBase
                    }

                    MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        anchors.fill: parent
                        onClicked: Managers.PipewireManager.setInput(modelData.sourceName)
                    }
                }
            }
        }
    }
}
