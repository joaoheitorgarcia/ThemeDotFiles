pragma Singleton
import QtQuick
import "../" as Singletons

QtObject {
    id: idleManager

    property bool enabled: false
    property bool initialized: false
    property bool busy: false

    function refreshState() {
        Singletons.CommandRunner.run([
            "sh",
            "-c",
            "pgrep -u \"$(id -u)\" -x hypridle >/dev/null && printf enabled || printf disabled"
        ], function(text) {
            enabled = text.trim() === "enabled"
            initialized = true
        })
    }

    function toggle() {
        if (busy) {
            return
        }

        const nextEnabled = !enabled
        const command = nextEnabled
            ? "nohup hypridle -q >/dev/null 2>&1 &"
            : "pkill -u \"$(id -u)\" -x hypridle"

        busy = true

        Singletons.CommandRunner.run(["sh", "-c", command], function() {
            busy = false
            refreshState()
            Singletons.CommandRunner.run([
                "notify-send",
                "-a",
                "Quickshell",
                "Auto lock/suspend",
                nextEnabled ? "Enabled" : "Disabled"
            ])
        })
    }

    Component.onCompleted: refreshState()

    property Timer refreshTimer: Timer {
        interval: 5000
        repeat: true
        running: true

        onTriggered: {
            if (!idleManager.busy) {
                idleManager.refreshState()
            }
        }
    }
}
