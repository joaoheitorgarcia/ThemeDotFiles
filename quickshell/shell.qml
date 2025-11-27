import Quickshell
import "Layers" as Layers

Scope {
    id: rootShell

    Variants {
        model: Quickshell.screens
        Layers.TopBar{}
    }
    Variants {
        model: Quickshell.screens
        Layers.Wallpaper{}
    }
    //TODO lockScreen
}
