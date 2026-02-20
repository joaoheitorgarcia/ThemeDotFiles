//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import "Layers" as Layers
import "Singletons" as Singletons
import "Singletons/Managers" as Managers

Scope {
    id: rootShell

    //BACKGROUND
    Variants {
        model: Quickshell.screens
        Layers.Wallpaper{
            WlrLayershell.layer: WlrLayer.Background
        }
    }

    //TOP
    Variants {
        model: Quickshell.screens
        Layers.PopupClickDetectionOverlay{
            WlrLayershell.layer: WlrLayer.Top
        }
    }

    Variants {
        model: Quickshell.screens
        Layers.TopBar{
            WlrLayershell.layer: WlrLayer.Top
        }
    }

    //OVERLAY
    Layers.Notifications{} //defaults to primary screen

    Layers.AppLauncher {
        id: appLauncher
        WlrLayershell.layer: WlrLayer.Overlay
    }

    //WALLPAPER PICKER

    Layers.WallpaperPicker{
        id:wallpaperPicker
        WlrLayershell.layer: WlrLayer.Overlay
    }


    //LOCK SCREEN
    Layers.LockScreen {
        id: lockScreen
        Component.onCompleted: Managers.SessionManager.lockScreen = lockScreen
    }

    //LAYER POKITAGENT
    Layers.PolkitAgent {}


    //----------- GLOBAL SHORTCUTS --------------//
    GlobalShortcut {
        name: "launcher-toggle"
        description: "Toggle QuickShell app launcher"

        onPressed: {
            appLauncher.toggle()
        }
    }

    GlobalShortcut {
        name: "lock-screen"
        description: "Lock Screen Shortcut"

        onPressed: {
            lockScreen.lock()
        }
    }

    GlobalShortcut {
        name: "toggle-wallpaper-picker"
        description: "Open wallpaper Picker"

        onPressed: {
            wallpaperPicker.toggle()
        }
    }
    //--------------------------------------------//

    //Surpress Reload Configs
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }
    }
}
