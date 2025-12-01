//@ pragma UseQApplication
import Quickshell
import QtQuick
import "Layers" as Layers
import "Singletons" as Singletons

Scope {

    //TODO find way to match theme dark mode from singleton
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
