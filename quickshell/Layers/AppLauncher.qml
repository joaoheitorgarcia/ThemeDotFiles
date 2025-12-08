import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../Singletons" as Singletons
import "../Singletons/Managers" as Managers

PanelWindow {
    id: launcher
    visible: false
    color: "transparent"
    focusable: true

    exclusiveZone: 0
    aboveWindows: true

    implicitWidth: 450
    implicitHeight: 250

    // Text currently in the search box
    property string query: ""

    Component.onCompleted: {
        Managers.PopupManager.register(launcher)
    }

    Component.onDestruction: {
        Managers.PopupManager.unregister(this)
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            TextField {
                id: searchField
                placeholderText: "Search apps…"
                placeholderTextColor: Singletons.Theme.mediumGray
                Layout.fillWidth: true
                font.pixelSize: 16
                color: Singletons.Theme.darkBase
                selectionColor: Singletons.Theme.accentSoftYellow
                selectedTextColor: Singletons.Theme.darkBase

                background: Item {
                    implicitHeight: 30

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 2
                        radius: 1
                        color: searchField.activeFocus
                               ? Singletons.Theme.accentSoft
                               : Singletons.Theme.mediumGray
                    }
                }

                onTextChanged: {
                    launcher.query = text
                    appListView.currentIndex = filteredApps.values.length > 0 ? 0 : -1
                }
            }

            ScriptModel {
                id: filteredApps

                values: {
                    const allEntries = [...DesktopEntries.applications.values]
                    return launcher.filterApplications(allEntries, launcher.query)
                }
            }

            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                clip: true

                model: filteredApps.values

                currentIndex: filteredApps.values.length > 0 ? 0 : -1
                keyNavigationWraps: true
                highlightFollowsCurrentItem: false

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        appListView.positionViewAtIndex(currentIndex, ListView.Contain)
                    }
                }

                delegate: Rectangle {
                    id: appListOption
                    property bool hovered: false

                    width: appListView.width
                    height: 55
                    radius: 8

                    color: (ListView.isCurrentItem || hovered) ?
                            Singletons.Theme.accentSoft:
                            "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        IconImage {
                            id: appIcon

                            readonly property string themedPath: Quickshell.iconPath(modelData.icon, true)

                            source: themedPath && themedPath !== ""
                                    ? themedPath
                                    : Qt.resolvedUrl("../Icons/regular/bx-window-alt.svg")

                            visible: source !== ""
                            width: 30
                            height: 30
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                        }

                        ColumnLayout {
                            width: parent.width - 30
                            spacing: 4

                            Text {
                                text: modelData ? modelData.name : "Unknown App"
                                font.pixelSize: 14
                                color: Singletons.Theme.darkBase
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.genericName !== "" ? modelData.genericName : modelData.comment
                                font.pixelSize: 10
                                color: Singletons.Theme.darkBase
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: appListOption.hovered = true
                        onExited: appListOption.hovered = false
                        onClicked: {
                            launcher.visible = false
                            modelData.execute()
                        }
                    }
                }
            }
        }

        Keys.onPressed: function (event) {
            if (!launcher.visible)
                return

            switch (event.key) {
            case Qt.Key_Up:
                if (appListView.currentIndex > 0)
                    appListView.currentIndex--
                event.accepted = true
                break
            case Qt.Key_Down:
                if (appListView.currentIndex < appListView.count - 1)
                    appListView.currentIndex++
                event.accepted = true
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (appListView.currentIndex >= 0 && filteredApps.values.length > 0) {
                    const entry = filteredApps.values[appListView.currentIndex]
                    launcher.visible = false
                    entry.execute()
                }
                event.accepted = true
                break
            case Qt.Key_Escape:
                toggle()
                event.accepted = true
                break
            }
        }
    }

    function toggle() {
        Managers.PopupManager.toggle(launcher)
        if (launcher.visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }

    function filterApplications(allEntries, query) {
        const q = (query || "").trim().toLowerCase()

        if (q === "")
            return allEntries

        return allEntries
            .map(function (entry) {
                const name    = (entry.name || "")
                const generic = (entry.genericName || "")
                const comment = (entry.comment || "")

                const nameLower    = name.toLowerCase()
                const genericLower = generic.toLowerCase()
                const commentLower = comment.toLowerCase()

                const exactName    = nameLower === q
                const exactGeneric = genericLower === q
                const exactComment = commentLower === q

                const containsName    = nameLower.includes(q)
                const containsGeneric = genericLower.includes(q)
                const containsComment = commentLower.includes(q)

                const contains = containsName || containsGeneric || containsComment

                return {
                    entry: entry,

                    exactName: exactName,
                    exactGeneric: exactGeneric,
                    exactComment: exactComment,

                    containsName: containsName,
                    containsGeneric: containsGeneric,
                    containsComment: containsComment,

                    contains: contains,

                    sortKey: nameLower || genericLower || commentLower
                }
            })
            .filter(function (item) {
                return item.contains || item.exactName || item.exactGeneric || item.exactComment
            })
            .sort(function (a, b) {
                // 1) exact name first
                if (a.exactName && !b.exactName) return -1
                if (!a.exactName && b.exactName) return 1

                // 2) then exact genericName
                if (a.exactGeneric && !b.exactGeneric) return -1
                if (!a.exactGeneric && b.exactGeneric) return 1

                // 3) then exact comment
                if (a.exactComment && !b.exactComment) return -1
                if (!a.exactComment && b.exactComment) return 1

                // 4) then partial matches in name
                if (a.containsName && !b.containsName) return -1
                if (!a.containsName && b.containsName) return 1

                // 5) then partial matches in genericName
                if (a.containsGeneric && !b.containsGeneric) return -1
                if (!a.containsGeneric && b.containsGeneric) return 1

                // 6) then partial matches in comment
                if (a.containsComment && !b.containsComment) return -1
                if (!a.containsComment && b.containsComment) return 1

                // 7) finally, alphabetical for stability
                if (a.sortKey < b.sortKey) return -1
                if (a.sortKey > b.sortKey) return 1
                return 0
            })
            .map(function (item) {
                return item.entry
            })
    }
}
