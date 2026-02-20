pragma Singleton
import QtQuick

QtObject {
    readonly property string font:
    loader.status === FontLoader.Ready ? loader.name : "Sans Serif"

    property FontLoader loader: FontLoader {
        source: Qt.resolvedUrl("../Fonts/Orbitron-Regular.ttf")
    }
}
