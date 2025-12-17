import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

PanelWindow {
    id: wallpaperPicker

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    visible: false
    color: "transparent"
    focusable: true
    aboveWindows: true
    exclusiveZone: 0

    implicitWidth: screen.width - screen.width / 20
    implicitHeight: screen.height - screen.height/2

    onVisibleChanged: {
        if (visible) {
            wallpaperPicker.ensureCurrentSelection()
            listScope.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        Managers.PopupManager.register(this)
    }

    Component.onDestruction: {
        Managers.PopupManager.unregister(this)
    }

    // List all images from <shellDir>/Wallpapers
    FolderListModel {
        id: wallpaperModel
        folder: "file://" + Quickshell.shellDir + "/Wallpapers"
        nameFilters: [ "*.png", "*.jpg", "*.jpeg", "*.webp" ]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        sortReversed: false

        onCountChanged: wallpaperPicker.ensureCurrentSelection()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Singletons.MatugenTheme.surfaceContainer
        border.color: Singletons.MatugenTheme.outline
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: "Choose wallpaper"
                color: Singletons.MatugenTheme.surfaceText
                font.pixelSize: 16
                Layout.fillWidth: true
            }

            FocusScope {
                id: listScope
                Layout.fillWidth: true
                Layout.fillHeight: true
                focus: wallpaperPicker.visible

                Keys.onEscapePressed: wallpaperPicker.visible = false

                Keys.onLeftPressed: (event) => {
                    if (wallpaperModel.count === 0) { event.accepted = true; return }

                    if (listView.currentIndex < 0) listView.currentIndex = 0
                    else listView.currentIndex = Math.max(0, listView.currentIndex - 1)

                    listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                    event.accepted = true
                }

                Keys.onRightPressed: (event) => {
                    if (wallpaperModel.count === 0) { event.accepted = true; return }

                    const last = wallpaperModel.count - 1
                    if (listView.currentIndex < 0) listView.currentIndex = 0
                    else listView.currentIndex = Math.min(last, listView.currentIndex + 1)

                    listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                    event.accepted = true
                }

                Keys.onEnterPressed: wallpaperPicker.selectCurrent()
                Keys.onReturnPressed: wallpaperPicker.selectCurrent()

                ListView {
                    id: listView
                    anchors.fill: parent

                    orientation: ListView.Horizontal
                    spacing: 12
                    model: wallpaperModel
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    interactive: false
                    focus: true
                    keyNavigationEnabled: true
                    keyNavigationWraps: false

                    highlightFollowsCurrentItem: true
                    highlightRangeMode: ListView.ApplyRange

                    preferredHighlightBegin: width * 0.5 - 110
                    preferredHighlightEnd:   width * 0.5 + 110

                    readonly property real viewCenterX: contentX + width / 2
                    readonly property real currentCenterX: currentItem ? (currentItem.x + currentItem.width / 2) : viewCenterX
                    readonly property real distFromCenter: Math.abs(currentCenterX - viewCenterX)

                    highlightMoveVelocity: 600 + distFromCenter * 4

                    delegate: Item {
                        id: wrapper
                        width: 200
                        height: listView.height - 20

                        property string fsPath: filePath

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Singletons.MatugenTheme.surface
                            border.width: wrapper.ListView.isCurrentItem ? 3 : 1
                            border.color: wrapper.ListView.isCurrentItem
                                          ? Singletons.MatugenTheme.primary
                                          : Singletons.MatugenTheme.outlineVariant

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Image {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    source: fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    clip: true
                                }

                                Text {
                                    text: fileName
                                    font.pixelSize: 11
                                    color: Singletons.MatugenTheme.surfaceText
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function toggle() {
        Managers.PopupManager.toggle(wallpaperPicker)
    }

    function ensureCurrentSelection() {
        if (wallpaperModel.count === 0)
            return

        const currentPath = Singletons.ConfigLoader.createWallpaperPath()
        let nextIndex = -1

        if (currentPath && currentPath.length > 0) {
            for (let i = 0; i < wallpaperModel.count; i++) {
                if (wallpaperModel.get(i, "filePath") === currentPath) {
                    nextIndex = i
                    break
                }
            }
        }

        if (nextIndex === -1 && listView.currentIndex >= 0 && listView.currentIndex < wallpaperModel.count)
            nextIndex = listView.currentIndex

        if (nextIndex === -1)
            nextIndex = 0

        listView.currentIndex = nextIndex
    }

    function selectWallpaper(path) {
        if (!path || path === "")
            return

        var idx = listView.currentIndex
        if (idx < 0 || idx >= wallpaperModel.count)
            idx = 0

        var fileName = wallpaperModel.get(idx, "fileName")
        Singletons.ConfigLoader.setWallpaperFile(fileName)

        const args = [ "matugen", "image", path ]
        Singletons.CommandRunner.run(args, function() {
            Quickshell.reload(false)
        })

        wallpaperPicker.visible = false
    }

    function selectCurrent() {
        if (wallpaperModel.count === 0)
            return

        var idx = listView.currentIndex
        if (idx < 0 || idx >= wallpaperModel.count)
            idx = 0

        listView.currentIndex = idx

        var filePath = wallpaperModel.get(idx, "filePath")
        wallpaperPicker.selectWallpaper(filePath)
    }
}
