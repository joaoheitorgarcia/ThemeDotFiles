import QtQuick
import "../Singletons" as Singletons
import "../FontLoaders" as FontLoaders

Rectangle{

    border.color: Singletons.Theme.darkBase
    border.width: 2

    color: Singletons.Theme.lightBackground
    radius: 6

    implicitHeight: Singletons.Theme.topBarItemHeight
    implicitWidth: (
        textItem.implicitWidth +
        Singletons.Theme.topBarItemHorizontalPadding *
        2
    )

    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: textItem
        anchors.centerIn: parent

        color: Singletons.Theme.darkBase
        font.pixelSize: Singletons.Theme.defaultFontSize
        font.family: Singletons.Theme.font
        text: Singletons.Time.time
    }
}




