//@ pragma UseQApplication
import Quickshell
import QtQuick
import "Layers" as Layers
import "Singletons" as Singletons

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

    Layers.Notifications{}

    //TODO lockScreen

}
