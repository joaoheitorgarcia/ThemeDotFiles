// Singletons/ConfigLoader.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: configLoader

    property bool ready: false

    property var generalFile: FileView {
        id: generalConfigFile
        path: Quickshell.shellDir + "/GeneralSettings.json"
        preload: true
        blockLoading: true
        watchChanges: true

        JsonAdapter {
            id: generalConfigs
            property string wallpaperFile: ""
            property var topBar
            property var notifications
            property var font
            property var icons
        }

        onAdapterUpdated: writeAdapter()
        onFileChanged: reload()
        onLoaded: {
            configLoader.ready = true
        }
        onLoadFailed: {
            console.warn("Config load failed:", error)
        }
    }

    Component.onCompleted: {
        generalConfigFile.waitForJob()
        ready = generalConfigFile.loaded
    }

    function getWallpaperFile(def="") {
        return ready && generalConfigs.wallpaperFile !== undefined ? generalConfigs.wallpaperFile : def
    }

    function getGeneralConfigs(){
        return ready ? generalConfigs : ({})
    }

    function createWallpaperPath(filePrefix=false) {
        const name = getWallpaperFile("")
        if (!name) return ""
        const full = Quickshell.shellDir + "/Wallpapers/" + name
        return filePrefix ? "file://" + full : full
    }

    function setWallpaperFile(name) {
        if (!name || name === "") return
        if (!ready) console.warn("ConfigLoader: file not loaded yet; write may be ignored")
        generalConfigs.wallpaperFile = name
        generalConfigFile.writeAdapter()
    }
}
