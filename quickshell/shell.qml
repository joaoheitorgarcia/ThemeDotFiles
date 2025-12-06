//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Wayland
import "Layers" as Layers
import "Singletons" as Singletons

Scope {
    id: rootShell

    Variants {
        model: Quickshell.screens
        Layers.Wallpaper{
            WlrLayershell.layer: WlrLayer.Background
        }
    }

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

    Layers.Notifications{}

    //TODO lockScreen
    //make command/shortcut cheatSheet

}
