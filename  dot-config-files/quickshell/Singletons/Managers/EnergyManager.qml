pragma Singleton
import QtQuick
import Quickshell.Services.UPower
import "../../Singletons" as Singletons

QtObject {
    id: energyManager

    readonly property var device: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery

    readonly property real percentage: (device && device.ready)
        ? device.percentage
        : 0

    readonly property int percentageInt: Math.round(percentage * 100)

    readonly property string timeToFullText: {
        if (!device || !device.ready)
            return ""
        return formatTime(device.timeToFull)
    }

    readonly property string timeToEmptyText: {
        if (!device || !device.ready)
            return ""
        return formatTime(device.timeToEmpty)
    }

    property var deviceWatcher: Connections {
        target: device

        function onPercentageChanged() {
            if(percentageInt == 15){
                Singletons.CommandRunner.run([
                    'notify-send',
                    '-a', 'Energy Manager',
                    '-u', 'critical',
                    'Battery Low',
                    percentageInt + '% remaining'
                ])
            }

            if(percentageInt == 5){
                Singletons.CommandRunner.run([
                    'notify-send',
                    '-a', 'Energy Manager',
                    '-u', 'critical',
                    'Battery Critically Low',
                    percentageInt + '% remaining'
                ])
            }
        }
    }

    function formatTime(seconds) {
        if (seconds <= 0)
            return ""

        const totalMinutes = Math.round(seconds / 60)
        const hours = Math.floor(totalMinutes / 60)
        const minutes = totalMinutes % 60

        if (hours > 0 && minutes > 0)
            return hours + "h " + minutes + "m"
        if (hours > 0)
            return hours + "h"
        return minutes + "m"
    }

    readonly property string stateString: {
        if (!device || !device.ready)
            return "Unknown"

        switch (device.state) {
        case UPowerDeviceState.Charging:
            return "Charging"
        case UPowerDeviceState.Discharging:
            return "Discharging"
        case UPowerDeviceState.FullyCharged:
            return "Fully Charged"
        case UPowerDeviceState.Empty:
            return "Empty"
        case UPowerDeviceState.PendingCharge:
            return "Pending charge"
        case UPowerDeviceState.PendingDischarge:
            return "Pending discharge"
        default:
            return "Unknown"
        }
    }

    // ─────────────────────────────
    // POWER MODE / POWER PROFILES
    // ─────────────────────────────
    // Requires power-profiles-daemon to be installed and running.
    // (This is exposed as a QML singleton PowerProfiles.)
    readonly property var powerProfiles: PowerProfiles

    readonly property int powerProfile: powerProfiles
        ? powerProfiles.profile
        : PowerProfile.Balanced

    readonly property string powerProfileLabel: {
        if (!powerProfiles)
            return "Unknown"

        switch (powerProfile) {
        case PowerProfile.PowerSaver:
            return "Power Saver"
        case PowerProfile.Performance:
            return "Performance"
        case PowerProfile.Balanced:
        default:
            return "Balanced"
        }
    }

    readonly property bool hasPerformanceProfile: powerProfiles
        ? powerProfiles.hasPerformanceProfile
        : false

    readonly property int degradationReason: powerProfiles
        ? powerProfiles.degradationReason
        : 0

    readonly property var holds: powerProfiles
        ? powerProfiles.holds
        : []

    function setPowerSaver() {
        if (powerProfiles)
            powerProfiles.profile = PowerProfile.PowerSaver;
    }

    function setBalanced() {
        if (powerProfiles)
            powerProfiles.profile = PowerProfile.Balanced;
    }

    function setPerformance() {
        if (powerProfiles && hasPerformanceProfile)
            powerProfiles.profile = PowerProfile.Performance;
    }
}
