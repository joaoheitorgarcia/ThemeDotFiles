pragma Singleton
import QtQuick

QtObject {
    id: sessionManager

    property var lockScreen

    function lock() {
        if (lockScreen) {
            lockScreen.lock()
        } else {
            console.warn("SessionManager.lock(): lockScreen not set yet")
        }
    }
}
