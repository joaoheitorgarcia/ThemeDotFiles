import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../../Singletons" as Singletons

// TODO select month and year by clicking on it
// reset calender on open of  modal

Item {
    id: calendarContent
    implicitWidth: 320
    implicitHeight: 300

    property date today: new Date()
    property int currentMonth: today.getMonth()
    property int currentYear: today.getFullYear()

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDayOfWeek(year, month) {
        return new Date(year, month, 1).getDay()
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Singletons.Theme.lightBackground
        border.color: Singletons.Theme.darkBase
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            anchors.topMargin: 18
            anchors.bottomMargin: 10
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 10

                Rectangle {
                    id: prevBtn
                    width: 28
                    height: 28
                    radius: height / 2
                    color: hovered ?
                            Singletons.Theme.accentSoftYellow :
                            Singletons.Theme.lightBackground

                    property bool hovered: false

                    Singletons.Icon {
                        id: leftArrowIcont
                        source: Singletons.Theme.iconArrowLeft
                        size: Singletons.Theme.iconDefaultSize
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Singletons.Theme.darkBase
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: prevBtn.hovered = true
                        onExited: prevBtn.hovered = false

                        onClicked: {
                            if (currentMonth === 0) {
                                currentMonth = 11
                                currentYear--
                            } else currentMonth--
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 16
                    color: Singletons.Theme.darkBase
                    font.bold: true
                    text: Qt.formatDate(new Date(currentYear, currentMonth, 1), "MMMM yyyy")
                }

                Rectangle {
                    id: nextBtn
                    width: 28
                    height: 28
                    radius: height / 2
                    color: hovered ?
                            Singletons.Theme.accentSoftYellow :
                            Singletons.Theme.lightBackground

                    property bool hovered: false

                    Singletons.Icon {
                        id: rightArrowIcont
                        source: Singletons.Theme.iconArrowRight
                        size: Singletons.Theme.iconDefaultSize
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Singletons.Theme.darkBase
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: nextBtn.hovered = true
                        onExited: nextBtn.hovered = false

                        onClicked: {
                            if (currentMonth === 11) {
                                currentMonth = 0
                                currentYear++
                            } else currentMonth++
                        }
                    }
                }
            }

            GridLayout {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 12
                        font.bold: true
                        color: Singletons.Theme.darkBase
                        text: modelData
                    }
                }

                Repeater {
                    model: firstDayOfWeek(currentYear, currentMonth)

                    Item {
                        Layout.fillWidth: true
                        height: 28
                    }
                }

                Repeater {
                    model: daysInMonth(currentYear, currentMonth)

                    Rectangle {
                        Layout.fillWidth: true
                        width: 32
                        height: 32
                        radius: 16

                        property int dayNum: index + 1

                        color: (dayNum === today.getDate()
                                && currentMonth === today.getMonth()
                                && currentYear === today.getFullYear())
                                ?
                                Singletons.Theme.accentSoft : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: dayNum
                            font.pixelSize: 13
                            color: Singletons.Theme.darkBase
                        }
                    }
                }
            }
        }
    }
}
