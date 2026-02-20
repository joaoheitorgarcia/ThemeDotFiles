import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Singletons" as Singletons
import "../../Singletons/Managers" as Managers

Item {
   id: volumeContent

   readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

   implicitWidth: 320
   implicitHeight: contentRect.implicitHeight

   property real _oldVolume: 0.5
   property real _oldInputVolume: 0.5
   property bool showApplications: true
   property bool showOutputs: false
   property bool showInputs: false

   Rectangle {
       id: contentRect
       anchors.fill: parent
       implicitHeight: contentColumn.implicitHeight +
                       contentColumn.anchors.topMargin +
                       contentColumn.anchors.bottomMargin
       radius: 12
       color: Singletons.MatugenTheme.surfaceContainer
       border.color: Singletons.MatugenTheme.outline
       border.width: 1

       Column {
           id: contentColumn
           anchors.fill: parent
           anchors.margins: 14
           spacing: 12

           Text {
               text: "Audio"
               font.bold: true
               font.pixelSize: 16
               color: Singletons.MatugenTheme.surfaceText
           }

           Item {
               width: parent.width
               height: 30

               RowLayout {
                   anchors.fill: parent
                   spacing: 10

                   Item {
                       Layout.preferredWidth: 22
                       Layout.preferredHeight: 22

                       Singletons.Icon {
                           id: volIcon
                           anchors.fill: parent
                           size: 22
                           color: Singletons.MatugenTheme.surfaceText
                           source: {
                               let vol = Managers.PipewireManager.volume
                               if (vol === 0) return generalConfigs.icons.volume.mute
                               if (vol < 0.33) return generalConfigs.icons.volume.low
                               if (vol < 0.66) return generalConfigs.icons.volume.medium
                               return generalConfigs.icons.volume.high
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
                           color: Singletons.MatugenTheme.surfaceVariant

                           Rectangle {
                               width: slider.visualPosition * parent.width
                               height: parent.height
                               radius: 2
                               color: Singletons.MatugenTheme.secondary
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
                           color: slider.pressed ? Singletons.MatugenTheme.secondary : Singletons.MatugenTheme.surfaceContainer
                           border.color: Singletons.MatugenTheme.outlineVariant
                           border.width: 1
                       }
                   }

                   Text {
                       text: Math.round(Managers.PipewireManager.volume * 100) + "%"
                       color: Singletons.MatugenTheme.surfaceText
                       font.pixelSize: 14
                   }
               }
           }

           Item {
               width: parent.width
               height: 30

               RowLayout {
                   anchors.fill: parent
                   spacing: 10

                   Item {
                       Layout.preferredWidth: 22
                       Layout.preferredHeight: 22

                       Singletons.Icon {
                           anchors.fill: parent
                           size: 22
                           color: Singletons.MatugenTheme.surfaceText
                           source: {
                               let vol = Managers.PipewireManager.inputVolume
                               if (vol === 0) return generalConfigs.icons.microphone.mute
                               return generalConfigs.icons.microphone.on
                           }
                       }

                       MouseArea {
                           cursorShape: Qt.PointingHandCursor
                           anchors.fill: parent
                           onClicked: {
                               if (Managers.PipewireManager.inputVolume > 0) {
                                   volumeContent._oldInputVolume = Managers.PipewireManager.inputVolume
                                   Managers.PipewireManager.setInputVolume(0)
                               } else {
                                   Managers.PipewireManager.setInputVolume(volumeContent._oldInputVolume || 0.5)
                               }
                           }
                       }
                   }

                   // SLIDER
                   Slider {
                       id: inputSlider
                       from: 0
                       to: 1
                       stepSize: 0.01
                       live: true

                       value: Managers.PipewireManager.inputVolume
                       onValueChanged: {
                           if (Math.abs(Managers.PipewireManager.inputVolume - value) > 0.001) {
                               Managers.PipewireManager.setInputVolume(value)
                           }
                       }

                       Layout.preferredWidth: 220

                       background: Rectangle {
                           id: inputSliderTrack
                           x: inputSlider.leftPadding
                           y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                           width: inputSlider.availableWidth
                           height: 4
                           radius: 2
                           color: Singletons.MatugenTheme.surfaceVariant

                           Rectangle {
                               width: inputSlider.visualPosition * parent.width
                               height: parent.height
                               radius: 2
                               color: Singletons.MatugenTheme.secondary
                           }

                           MouseArea {
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
                                   const handleHalf = inputSlider.handle.width
                                   const x = mouseX - handleHalf
                                   const ratio = x / (inputSliderTrack.width - inputSlider.handle.width)

                                   const clamped = Math.max(0, Math.min(1, ratio))
                                   inputSlider.value = inputSlider.from + (inputSlider.to - inputSlider.from) * clamped
                               }
                           }
                       }

                       handle: Rectangle {
                           x: inputSlider.leftPadding + inputSlider.visualPosition * (inputSlider.availableWidth - width)
                           y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                           width: 16
                           height: 16
                           radius: 8
                           color: inputSlider.pressed ? Singletons.MatugenTheme.secondary : Singletons.MatugenTheme.surfaceContainer
                           border.color: Singletons.MatugenTheme.outlineVariant
                           border.width: 1
                       }
                   }

                   Text {
                       text: Math.round(Managers.PipewireManager.inputVolume * 100) + "%"
                       color: Singletons.MatugenTheme.surfaceText
                       font.pixelSize: 14
                   }
               }
           }

           Item {
               width: parent.width
               height: 26

               RowLayout {
                   anchors.fill: parent
                   spacing: 6

                   Text {
                       text: "Applications"
                       font.bold: true
                       font.pixelSize: 14
                       color: Singletons.MatugenTheme.surfaceText
                       verticalAlignment: Text.AlignVCenter
                   }

                   Item { Layout.fillWidth: true }

                   Singletons.Icon {
                       size: 16
                       Layout.preferredWidth: 16
                       Layout.preferredHeight: 16
                       source: volumeContent.showApplications ? generalConfigs.icons.general.collapseUp : generalConfigs.icons.general.collapseDown
                       color: Singletons.MatugenTheme.surfaceText
                   }
               }

               MouseArea {
                   anchors.fill: parent
                   cursorShape: Qt.PointingHandCursor
                   onClicked: volumeContent.showApplications = !volumeContent.showApplications
               }
           }

            ListView {
                id: appList
                width: parent.width
                model: Managers.PipewireManager.sinkInputs
                height: volumeContent.showApplications ? Math.min(count * 56, 260) : 0
                visible: volumeContent.showApplications
                clip: true
                interactive: contentHeight > height

                delegate: Rectangle {
                    width: appList.width
                    height: 56
                    radius: 6
                   color: hovered ? Singletons.MatugenTheme.surfaceVariant : "transparent"

                   property bool hovered: false

                   HoverHandler {
                       id: appHover
                       acceptedButtons: Qt.NoButton
                       onHoveredChanged: parent.hovered = hovered
                   }

                   ColumnLayout {
                       anchors.fill: parent
                       anchors.margins: 6
                       spacing: 4

                       Text {
                           text: modelData.name || ""
                           color: Singletons.MatugenTheme.surfaceText
                           font.pixelSize: 13
                           Layout.fillWidth: true
                           elide: Text.ElideRight
                       }

                       RowLayout {
                           Layout.fillWidth: true
                           spacing: 8

                           Item {
                               Layout.preferredWidth: 22
                               Layout.preferredHeight: 22

                               Singletons.Icon {
                                   anchors.fill: parent
                                   size: 22
                                   color: Singletons.MatugenTheme.surfaceText
                                   source: {
                                       const vol = appSlider.value || 0
                                       if (modelData.muted && !appSlider.userDragging) return generalConfigs.icons.volume.mute
                                       if (vol === 0) return generalConfigs.icons.volume.mute
                                       if (vol < 0.33) return generalConfigs.icons.volume.low
                                       if (vol < 0.66) return generalConfigs.icons.volume.medium
                                       return generalConfigs.icons.volume.high
                                   }
                               }

                               MouseArea {
                                   anchors.fill: parent
                                   cursorShape: Qt.PointingHandCursor
                                   onClicked: Managers.PipewireManager.setAppMute(modelData.id, !modelData.muted)
                               }
                           }

                           Slider {
                               id: appSlider
                               from: 0
                               to: 1
                               stepSize: 0.01
                               live: true

                               property bool userDragging: false

                               value: 0

                               Binding {
                                   target: appSlider
                                   property: "value"
                                   value: modelData && modelData.volume !== undefined ? modelData.volume : 0
                                   when: !appSlider.userDragging
                                   restoreMode: Binding.RestoreBinding
                               }

                               onValueChanged: {
                                   const current = modelData && modelData.volume !== undefined ? modelData.volume : 0;
                                   if (Math.abs(current - value) > 0.001) {
                                       Managers.PipewireManager.setAppVolume(modelData.id, value, !userDragging)
                                   }
                               }

                               onPressedChanged: {
                                   if (pressed) {
                                       userDragging = true
                                   } else if (userDragging) {
                                       commitVolume()
                                       userDragging = false
                                   }
                               }

                               function commitVolume() {
                                   const current = modelData && modelData.volume !== undefined ? modelData.volume : 0;
                                   if (Math.abs(current - value) > 0.001) {
                                       Managers.PipewireManager.setAppVolume(modelData.id, value, true)
                                   }
                               }

                               Layout.fillWidth: true

                               background: Rectangle {
                                   id: appSliderTrack
                                   x: appSlider.leftPadding
                                   y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                   width: appSlider.availableWidth
                                   height: 4
                                   radius: 2
                                   color: Singletons.MatugenTheme.surfaceVariant

                                   Rectangle {
                                       width: appSlider.visualPosition * parent.width
                                       height: parent.height
                                       radius: 2
                                       color: Singletons.MatugenTheme.secondary
                                   }

                                   MouseArea {
                                       id: appTrackMouse
                                       anchors.top: parent.top
                                       anchors.bottom: parent.bottom
                                       anchors.left: parent.left
                                       anchors.right: parent.right
                                       anchors.margins: -10
                                       hoverEnabled: true
                                       cursorShape: Qt.PointingHandCursor
                                       drag.target: null
                                       preventStealing: true

                                       onPressed: (mouse) => {
                                           appSlider.userDragging = true
                                           updateVolume(mouse.x)
                                       }

                                       onReleased: {
                                           appSlider.commitVolume()
                                           appSlider.userDragging = false
                                       }

                                       onCanceled: {
                                           appSlider.commitVolume()
                                           appSlider.userDragging = false
                                       }

                                       onPositionChanged: (mouse) => {
                                           if (pressed) {
                                               updateVolume(mouse.x)
                                           }
                                       }

                                       function updateVolume(mouseX) {
                                           const handleHalf = appSlider.handle.width
                                           const x = mouseX - handleHalf
                                           const ratio = x / (appSliderTrack.width - appSlider.handle.width)

                                           const clamped = Math.max(0, Math.min(1, ratio))
                                           appSlider.value = appSlider.from + (appSlider.to - appSlider.from) * clamped
                                       }
                                   }
                               }

                               handle: Rectangle {
                                   x: appSlider.leftPadding + appSlider.visualPosition * (appSlider.availableWidth - width)
                                   y: appSlider.topPadding + appSlider.availableHeight / 2 - height / 2
                                   width: 16
                                   height: 16
                                   radius: 8
                                   color: appSlider.pressed ? Singletons.MatugenTheme.secondary : Singletons.MatugenTheme.surfaceContainer
                                   border.color: Singletons.MatugenTheme.outlineVariant
                                   border.width: 1
                               }
                           }

                           Text {
                               text: Math.round((appSlider.value || 0) * 100) + "%"
                               color: Singletons.MatugenTheme.surfaceText
                               font.pixelSize: 13
                               Layout.preferredWidth: 40
                               horizontalAlignment: Text.AlignRight
                               verticalAlignment: Text.AlignVCenter
                           }
                       }
                   }
               }
           }

           Item {
               width: parent.width
               height: 26

               RowLayout {
                   anchors.fill: parent
                   spacing: 6

                   Text {
                       text: "Output"
                       font.bold: true
                       font.pixelSize: 14
                       color: Singletons.MatugenTheme.surfaceText
                       verticalAlignment: Text.AlignVCenter
                   }

                   Item { Layout.fillWidth: true }

                   Singletons.Icon {
                       size: 16
                       Layout.preferredWidth: 16
                       Layout.preferredHeight: 16
                       source: volumeContent.showOutputs ? generalConfigs.icons.general.collapseUp : generalConfigs.icons.general.collapseDown
                       color: Singletons.MatugenTheme.surfaceText
                   }
               }

               MouseArea {
                   anchors.fill: parent
                   cursorShape: Qt.PointingHandCursor
                   onClicked: volumeContent.showOutputs = !volumeContent.showOutputs
               }
           }

           ListView {
               id: outputList
               width: parent.width
               model: Managers.PipewireManager.outputs
               height: volumeContent.showOutputs ? Math.min(count * 30, 150) : 0
               visible: volumeContent.showOutputs
               clip: true
               interactive: false

               delegate: Rectangle {
                   width: outputList.width
                   height: 30
                   color: modelData.default ? Singletons.MatugenTheme.secondaryContainer : hovered ? Singletons.MatugenTheme.surfaceVariant : "transparent"
                   radius: 6

                   property bool hovered: false

                   Text {
                       text: modelData.name || ""
                       anchors.verticalCenter: parent.verticalCenter
                       anchors.left: parent.left
                       anchors.leftMargin: 6
                           color: modelData.default
                                  ? Singletons.MatugenTheme.secondaryContainerText
                                  : Singletons.MatugenTheme.surfaceText
                       }

                   MouseArea {
                       cursorShape: Qt.PointingHandCursor
                       anchors.fill: parent
                       hoverEnabled: true
                       onEntered: parent.hovered = true
                       onExited: parent.hovered = false
                       onClicked: Managers.PipewireManager.setOutput(modelData.sinkName)
                   }
               }
           }

           Item {
               width: parent.width
               height: 26

               RowLayout {
                   anchors.fill: parent
                   spacing: 6

                   Text {
                       text: "Input"
                       font.bold: true
                       font.pixelSize: 14
                       color: Singletons.MatugenTheme.surfaceText
                       verticalAlignment: Text.AlignVCenter
                   }

                   Item { Layout.fillWidth: true }

                   Singletons.Icon {
                       size: 16
                       Layout.preferredWidth: 16
                       Layout.preferredHeight: 16
                       source: volumeContent.showInputs ? generalConfigs.icons.general.collapseUp : generalConfigs.icons.general.collapseDown
                       color: Singletons.MatugenTheme.surfaceText
                   }
               }

               MouseArea {
                   anchors.fill: parent
                   cursorShape: Qt.PointingHandCursor
                   onClicked: volumeContent.showInputs = !volumeContent.showInputs
               }
           }

           ListView {
               id: inputList
               width: parent.width
               model: Managers.PipewireManager.inputs
               height: volumeContent.showInputs ? Math.min(count * 30, 150) : 0
               visible: volumeContent.showInputs
               clip: true

               delegate: Rectangle {
                   width: inputList.width
                   height: 30
                   color: modelData.default ? Singletons.MatugenTheme.secondaryContainer : hovered ? Singletons.MatugenTheme.surfaceVariant : "transparent"
                   radius: 6

                   property bool hovered: false

                   Text {
                       text: modelData.name || ""
                       anchors.verticalCenter: parent.verticalCenter
                       anchors.left: parent.left
                       anchors.leftMargin: 6
                       color: modelData.default
                              ? Singletons.MatugenTheme.secondaryContainerText
                              : Singletons.MatugenTheme.surfaceText
                   }

                   MouseArea {
                       cursorShape: Qt.PointingHandCursor
                       anchors.fill: parent
                       hoverEnabled: true
                       onEntered: parent.hovered = true
                       onExited: parent.hovered = false
                       onClicked: Managers.PipewireManager.setInput(modelData.sourceName)
                   }
               }
           }
       }
   }
}
