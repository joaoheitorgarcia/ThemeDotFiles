pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: time

    property SystemClock clock: SystemClock {
        precision: SystemClock.Seconds
    }

    readonly property string time: Qt.formatDateTime(
        clock.date,
        "HH:mm"
    )

    readonly property string date: Qt.formatDateTime(
        clock.date,
        "dd MMMM yyyy"
    )
}
