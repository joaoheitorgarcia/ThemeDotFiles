import AstalBattery from "gi://AstalBattery"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { createBinding, createComputed, With } from "gnim"
import BoxIcon from "../Common/BoxIcon"
import { Gtk } from "ags/gtk4"

type PowerProfileOption = {
    id: string
    label: string
    icon: string
}

const powerProfileOptions: PowerProfileOption[] = [
    { id: "power-saver", label: "Saver", icon: "leaf" },
    { id: "balanced", label: "Balanced", icon: "tachometer" },
    { id: "performance", label: "Performance", icon: "rocket" },
]

export default function BatteryInfo() {
    const batteryDevice = AstalBattery.get_default()
    const powerProfiles = AstalPowerProfiles.get_default()

    const percentage = createBinding(batteryDevice, "percentage")
    const charging = createBinding(batteryDevice, "charging")
    const batteryState = createBinding(batteryDevice, "state")
    const batteryIconName = createBinding(batteryDevice, "battery-icon-name")
    const timeToEmpty = createBinding(batteryDevice, "time-to-empty")
    const timeToFull = createBinding(batteryDevice, "time-to-full")
    const energyRate = createBinding(batteryDevice, "energy-rate")
    const capacity = createBinding(batteryDevice, "capacity")
    const activeProfile = createBinding(powerProfiles, "active-profile")
    const availableProfiles = createBinding(powerProfiles, "profiles").as((profiles) =>
        Array.from(profiles ?? []).map((profile: any) => profile.profile),
    )

    type BatteryIconObject = {
        id: string
        label: string
        icon: string
        iconColor: string
    }

    const batteryStates: BatteryIconObject[] = [
        { id: "critical", label: "Critical", icon: "battery", iconColor: "#db2a2a" },
        { id: "low", label: "Low", icon: "battery-low", iconColor: "#dba02a" },
        { id: "medium", label: "Normal", icon: "battery-low", iconColor: "default" },
        { id: "high", label: "High", icon: "battery-full", iconColor: "default" },
        { id: "full", label: "Full", icon: "battery-full", iconColor: "default" },
        { id: "charging", label: "Charging", icon: "bolt-circle", iconColor: "default" },
    ]

    function getCurrentBatteryState(): BatteryIconObject | undefined {
        const percent = percentage()
        const isCharging = charging()
        let stateId = "full"

        if (isCharging) {
            stateId = "charging"
        } else {
            switch (true) {
                case percent <= 0.05:
                    stateId = "critical"
                    break
                case percent <= 0.15:
                    stateId = "low"
                    break
                case percent < 0.5:
                    stateId = "high"
                    break
                case percent < 0.95:
                    stateId = "high"
                    break
            }
        }
        return batteryStates.find((state) => state.id === stateId)
    }

    function getBatteryStateString(): string {
        const state = batteryState()
        switch (state) {
            default:
            case 0:
                return "Unknow"
            case 1:
                return "Charging"
            case 2:
                return "Discharging"
            case 3:
                return "Empty"
            case 4:
                return "Fully Charged"
            case 5:
                return "Pending Charge"
            case 6:
                return "Pending Discharge"
        }
    }

    function getPercentageString(): string {
        const percent = percentage()
        return String((percent * 100).toFixed(0)) + "%"
    }

    function getTimeToString(): string {
        const isCharging = charging()
        const toFull = timeToFull()
        const toEmpty = timeToEmpty()

        function formatSeconds(seconds: number): string {
            if (seconds <= 0) return ""

            const minutes = Math.round(seconds / 60)
            const hours = Math.floor(minutes / 60)
            const restMinutes = minutes % 60

            if (hours > 0 && restMinutes > 0)
                return `${hours}h ${restMinutes}m`
            if (hours > 0)
                return `${hours}h`
            return `${restMinutes}m`
        }

        if (isCharging) {
            if (toFull == 0) {
                return "Fully Charged"
            }
            return formatSeconds(toFull) + " to full charge"
        } else {
            return formatSeconds(toEmpty) + " remaining"
        }
    }
    
    function getEnergyRateString(): string {
        const rate = Math.abs(energyRate())

        if (!Number.isFinite(rate) || rate <= 0) {
            return "Unknown"
        }

        return `${rate.toFixed(1)} W`
    }

    function getCapacityString(): string {
        const value = capacity()

        if (!Number.isFinite(value) || value <= 0) {
            return "Unknown"
        }

        return `${Math.round(value * 100)}%`
    }

    function getActiveProfileLabel(): string {
        switch (activeProfile()) {
            case "power-saver":
                return "Power Saver"
            case "performance":
                return "Performance"
            case "balanced":
                return "Balanced"
            default:
                return "Unknown"
        }
    }

    function setPowerProfile(profile: string) {
        if (activeProfile() !== profile) {
            powerProfiles.active_profile = profile
        }
    }

    const percentageString = createComputed(() => getPercentageString())
    const batteryStateString = createComputed(() => getBatteryStateString())
    const timeToString = createComputed(() => getTimeToString())
    const currentBatteryState = createComputed(() => getCurrentBatteryState())
    const energyRateString = createComputed(() => getEnergyRateString())
    const capacityString = createComputed(() => getCapacityString())
    const activeProfileLabel = createComputed(() => getActiveProfileLabel())


    return (
        <menubutton
            class="batteryButton"
            $={(button) => button.set_cursor_from_name("pointer")}
        >
            <BoxIcon
                name={currentBatteryState()?.icon ?? 'Error'}
                size={18}
                class="icon"
                color={currentBatteryState()?.iconColor ?? 'default'}
            />
            <popover hasArrow={false}>
                <box
                    class="batteryPopoverContent"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={12}
                >
                    <label
                        class="batteryPopoverTitle"
                        label="Energy"
                        halign={Gtk.Align.START}
                        xalign={0}
                    />

                    <box
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={8}
                    >
                        <box spacing={10}>
                            <image
                                iconName={batteryIconName}
                                pixelSize={18}
                                class="icon"
                            />

                            <box
                                orientation={Gtk.Orientation.VERTICAL}
                                spacing={2}
                                valign={Gtk.Align.CENTER}
                                hexpand
                            >
                                <box spacing={8}>
                                    <label
                                        class="batteryPercent"
                                        label={percentageString}
                                        halign={Gtk.Align.START}
                                        xalign={0}
                                    />
                                    <label
                                        label="-"
                                        halign={Gtk.Align.START}
                                        xalign={0}
                                    />
                                    <label
                                        class="batteryState"
                                        label={batteryStateString}
                                        halign={Gtk.Align.START}
                                        xalign={0}
                                    />
                                </box>

                                <label
                                    class="batteryTime"
                                    label={timeToString}
                                    visible={timeToString((value) => value.length > 0)}
                                    halign={Gtk.Align.START}
                                    xalign={0}
                                />
                            </box>
                        </box>

                        <levelbar
                            class="batteryLevel"
                            minValue={0}
                            maxValue={1}
                            mode={Gtk.LevelBarMode.CONTINUOUS}
                            value={percentage}
                            heightRequest={8}
                            widthRequest={260}
                            hexpand
                        />
                    </box>

                    <box
                        class="batteryStats"
                        spacing={10}
                    >
                        <box
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={2}
                            hexpand
                        >
                            <label
                                class="batteryStatLabel"
                                label="Rate"
                                halign={Gtk.Align.START}
                                xalign={0}
                            />
                            <label
                                class="batteryStatValue"
                                label={energyRateString}
                                halign={Gtk.Align.START}
                                xalign={0}
                            />
                        </box>

                        <box
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={2}
                            hexpand
                        >
                            <label
                                class="batteryStatLabel"
                                label="Health"
                                halign={Gtk.Align.START}
                                xalign={0}
                            />
                            <label
                                class="batteryStatValue"
                                label={capacityString}
                                halign={Gtk.Align.START}
                                xalign={0}
                            />
                        </box>
                    </box>

                    <box
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={6}
                    >
                        <box spacing={8}>
                            <label
                                class="batteryModeLabel"
                                label="Power Mode"
                                halign={Gtk.Align.START}
                                xalign={0}
                                hexpand
                            />
                            <label
                                class="batteryModeValue"
                                label={activeProfileLabel}
                                halign={Gtk.Align.END}
                                xalign={1}
                            />
                        </box>

                        <box spacing={6}>
                            {powerProfileOptions.map((option) => (
                                <button
                                    class={activeProfile((profile) =>
                                        profile === option.id
                                            ? "popoverMenuAction btnHovered"
                                            : "popoverMenuAction"
                                    )}
                                    visible={availableProfiles((profiles) => profiles.includes(option.id))}
                                    onClicked={() => setPowerProfile(option.id)}
                                    $={(button) => button.set_cursor_from_name("pointer")}
                                >
                                    <box spacing={6}>
                                        <BoxIcon
                                            name={option.icon}
                                            size={14}
                                            class="icon"
                                        />
                                        <label label={option.label} />
                                    </box>
                                </button>
                            ))}
                        </box>
                    </box>
                </box>
            </popover>
        </menubutton>

    )
}
