import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property alias source: icon.source
    property int size: 20
    property color color: "white"

    implicitHeight: size
    implicitWidth: size

    Image {
        id: icon
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth:true
    }

    ColorOverlay {
        anchors.fill: icon
        source: icon
        color: root.color
    }
}
