import Quickshell
import QtQuick

// Video
//import QtMultimedia
import "../Singletons" as Singletons

PanelWindow {
    required property var modelData
    screen: modelData

    id: wallpaper
    exclusionMode: ExclusionMode.Ignore

    anchors{
        top:true
        right:true
        bottom:true
        left:true
    }

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: Singletons.ConfigLoader.createWallpaperPath()
    }

//    Video {
//        id: bgVideo
//        anchors.fill: parent
//        source: "file://$HOME/Pictures/VideoWallpapers/background.mp4"
//
//        loops: MediaPlayer.Infinite
//        autoPlay: true
//        muted: true
//        fillMode: VideoOutput.PreserveAspectCrop
//    }
}
