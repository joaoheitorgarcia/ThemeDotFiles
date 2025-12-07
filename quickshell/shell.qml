//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import "Layers" as Layers
import "Singletons" as Singletons

Scope {
    id: rootShell

    //Background
    Variants {
        model: Quickshell.screens
        Layers.Wallpaper{
            WlrLayershell.layer: WlrLayer.Background
        }
    }

    //Top
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

    //OverLay
    Layers.Notifications{} //defaults to primary screen

    Layers.AppLauncher {
        id: appLauncher
        WlrLayershell.layer: WlrLayer.Overlay
    }

    GlobalShortcut {
        name: "launcher-toggle"
        description: "Toggle QuickShell app launcher"

        onPressed: {
            appLauncher.toggle()
        }
    }
}
