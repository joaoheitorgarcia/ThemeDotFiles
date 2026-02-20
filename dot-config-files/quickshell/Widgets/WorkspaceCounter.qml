import QtQuick
import Quickshell.Hyprland
import "../Singletons" as Singletons

Row {
    id: workspaceCounter

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    spacing: 6
    height: generalConfigs.topBar.itemHeight

    Component.onCompleted: Hyprland.refreshWorkspaces()

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: workspacePill

            readonly property var workspace: modelData
            readonly property bool isFocused: workspace && workspace.focused
            readonly property bool isActive: workspace && workspace.active
            readonly property bool isUrgent: workspace && workspace.urgent
            readonly property string displayName: {
                if (!workspace) {
                    return ""
                }

                if (workspace.name && workspace.name.length > 0) {
                    var normalizedName = workspace.name.toLowerCase()
                    if (normalizedName === "special" || normalizedName.startsWith("special:")) {
                        return "S"
                    }
                    return workspace.name
                }

                if (workspace.id < 0) {
                    return "S"
                }

                return String(workspace.id)
            }

            height: generalConfigs.topBar.itemHeight
            radius: 8
            border.width: 2

            color: isActive
                  ? Singletons.MatugenTheme.surfaceContainerHighest
                  : Singletons.MatugenTheme.surfaceContainer

            border.color: isUrgent
                  ? Singletons.MatugenTheme.errorColor
                  : Singletons.MatugenTheme.surfaceVariantText

            implicitWidth: Math.max(
                height,
                label.implicitWidth + generalConfigs.topBar.itemHorizontalPadding * 2
            )

            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: label
                anchors.centerIn: parent
                text: displayName
                color: isFocused
                    ? Singletons.MatugenTheme.primaryContainerText
                    : Singletons.MatugenTheme.surfaceText
                font.pixelSize: generalConfigs.font.normalSize
                font.family: Singletons.FontLoader.font
            }

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (workspace) {
                        workspace.activate()
                    }
                }
            }
        }
    }
}
