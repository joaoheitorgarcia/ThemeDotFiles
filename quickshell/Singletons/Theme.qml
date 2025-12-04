pragma Singleton
import QtQuick
import Quickshell
import "../FontLoaders" as FontLoaders

QtObject {
    id: theme

    //TopBar Variables
    readonly property int topBarHeight: 40
    readonly property int topBarItemHeight: topBarHeight - topBarHeight / 4
    readonly property double topBarItemHorizontalPadding: 7.5

    //wallpaper Path
    function createWallpaperPath() {
        const base = "file://$HOME/Pictures/Wallpapers/";
        const fileName = "ghost_in_the_shell"
        return base + fileName;
    }
    readonly property string wallpaperPath: createWallpaperPath()

    //Notification Vars
    property int  maxVisibleNotifications: 3

    //Font
    readonly property string font: FontLoaders.Roboto.font
    readonly property int defaultFontSize: 18

    //───────────────
    //    Colors
    //───────────────    

    //theme
    readonly property string darkBase: "#303e4d"
    readonly property string lightBackground: "#e6ecef"
    readonly property string mediumGray: "#aab0ba"
    readonly property string accentSoft: "#c8ccd2"
    readonly property string accentSoftYellow: "#e8e0c8"
    readonly property string hightlightBlue: "#4da3ff"
    readonly property string hightlightTeal: "#58c7b8"
    readonly property string hightlightRed: "#ff605a"

    //energyLevelsColors
    readonly property string lowEnergy: "#e24a4a"
    readonly property string mediumEnergy: "#e29b3b"
    readonly property string hightEnergy: "#7ebf56"

    //───────────────
    // icon Path Svg
    //───────────────

    //general
    readonly property int iconDefaultSize: 18
    readonly property string iconClose: "../Icons/regular/bx-x.svg"

    //Network
    readonly property string iconWired: "../Icons/regular/bx-network-chart.svg"
    readonly property string iconWifiStrength3: "../Icons/regular/bx-wifi.svg"
    readonly property string iconWifiStrength2: "../Icons/regular/bx-wifi-2.svg"
    readonly property string iconWifiStrength1: "../Icons/regular/bx-wifi-1.svg"
    readonly property string iconWifiStrength0: "../Icons/regular/bx-wifi-0.svg"
    readonly property string iconWifiStrengthSlash: "../Icons/regular/bx-wifi-off.svg"
    readonly property string iconSignalStrengthNoSignal: "../Icons/regular/bx-no-signal.svg"
    readonly property string iconSignalStrength1: "../Icons/regular/bx-signal-1.svg"
    readonly property string iconSignalStrength2: "../Icons/regular/bx-signal-2.svg"
    readonly property string iconSignalStrength3: "../Icons/regular/bx-signal-3.svg"
    readonly property string iconSignalStrength4: "../Icons/regular/bx-signal-4.svg"
    readonly property string iconSignalStrength5: "../Icons/regular/bx-signal-5.svg"

    //powerMenu
    readonly property string iconPowerMenu: "../Icons/regular/bx-power-off.svg"
    readonly property string iconPowerSuspend: "../Icons/regular/bx-leaf.svg"
    readonly property string iconPowerHibernate: "../Icons/regular/bx-moon.svg"
    readonly property string iconPowerLock: "../Icons/regular/bx-lock.svg"
    readonly property string iconPowerReboot: "../Icons/regular/bx-reset.svg"
    readonly property string iconPowerShutdow: "../Icons/regular/bx-power-off.svg"

    //Energy
    readonly property string iconBatteryFull: "../Icons/regular/bx-battery-full.svg"
    readonly property string iconBatteryMedium: "../Icons/regular/bx-battery-low.svg"
    readonly property string iconBatteryLow: "../Icons/regular/bx-battery-1.svg"
    readonly property string iconBatteryEmpty: "../Icons/regular/bx-battery.svg"
    readonly property string iconBatteryCharging: "../Icons/regular/bx-bolt-circle.svg"

    //Volume
    readonly property string iconVolumeHigh: "../Icons/regular/bx-volume-full.svg"
    readonly property string iconVolumeMedium: "../Icons/regular/bx-volume-low.svg"
    readonly property string iconVolumeLow: "../Icons/regular/bx-volume.svg"
    readonly property string iconVolumeMute: "../Icons/regular/bx-volume-mute.svg"

    //Bluetooth
    readonly property string iconBluetooth: "../Icons/regular/bx-bluetooth.svg"
    readonly property string iconBluetoothPaired: "../Icons/regular/bx-check.svg"
    readonly property string iconBluetoothPairing: "../Icons/regular/bx-loader.svg"
    readonly property string iconBluetoothBonded: "../Icons/regular/bx-save.svg"

    //Notification
    readonly property string iconNotificationList: "../Icons/regular/bx-message-notification.svg"
}
