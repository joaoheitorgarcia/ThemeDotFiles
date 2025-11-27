pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    property bool debug: false

    function run(cmdArray, onFinished) {
        if(debug){
           console.log("[CmdRunner] run →", cmdArray.join(" "))
        }

        const proc = Qt.createQmlObject(`
            import Quickshell.Io; Process { running: true }
        `, Qt.application, "runner")

        proc.command = cmdArray

        const collector = Qt.createQmlObject(`
            import Quickshell.Io; StdioCollector {}
        `, proc, "collector")

        collector.onStreamFinished.connect(function() {
            if(debug){
                console.log("[CmdRunner] output for", cmdArray.join(" "), "→", collector.text.trim())
            }
            onFinished?.(collector.text)
            proc.destroy()
        })

        proc.exited.connect(function(exitCode, exitStatus) {
            if(debug){
                console.log("[CmdRunner] exited code:", exitCode, "status:", exitStatus, "cmd:", cmdArray.join(" "))
            }
        })

        proc.stdout = collector
    }
}
