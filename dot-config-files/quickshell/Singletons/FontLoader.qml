pragma Singleton
import QtQuick
import "." as Singletons

QtObject {
    readonly property string font:
    loader.status === FontLoader.Ready ? loader.name : "Sans Serif"

    readonly property var generalConfigs: Singletons.ConfigLoader.getGeneralConfigs()

    property FontLoader loader: FontLoader {
        source: Qt.resolvedUrl(generalConfigs.font.filePath)
    }
}
