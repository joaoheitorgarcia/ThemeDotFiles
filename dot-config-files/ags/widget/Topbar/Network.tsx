import Gio from "gi://Gio?version=2.0"
import AstalNetwork from "gi://AstalNetwork"
import Gtk from "gi://Gtk?version=4.0"
import Pango from "gi://Pango?version=1.0"
import { createBinding, createComputed, createState, For, type Accessor } from "gnim"
import BoxIcon from "../Common/BoxIcon"

type Wifi = any
type AccessPoint = any

const network = AstalNetwork.get_default()

const [selectedAccessPoint, setSelectedAccessPoint] = createState<AccessPoint | null>(null)
const [password, setPassword] = createState("")
const [showPassword, setShowPassword] = createState(false)
const [connectingPath, setConnectingPath] = createState("")
const [connectionError, setConnectionError] = createState("")

function closePasswordPrompt() {
    setSelectedAccessPoint(null)
    setPassword("")
    setShowPassword(false)
    setConnectionError("")
}

function signalIcon(strength: number, offlineIcon = "wifi-slash") {
    if (strength <= 0) return offlineIcon
    if (strength < 25) return "wifi-0"
    if (strength < 50) return "wifi-1"
    if (strength < 75) return "wifi-2"
    return "wifi"
}

function getAccessPointId(accessPoint: AccessPoint | null | undefined) {
    if (!accessPoint) {
        return ""
    }

    return `${String(accessPoint.ssid ?? "")}:${String(accessPoint.bssid ?? "")}`
}

function getAccessPointSsid(accessPoint: AccessPoint | null | undefined) {
    return String(accessPoint?.ssid ?? "").trim()
}

function getAccessPointBssid(accessPoint: AccessPoint | null | undefined) {
    return String(accessPoint?.bssid ?? "").trim()
}

function isSecureAccessPoint(accessPoint: AccessPoint | null | undefined) {
    return Boolean(accessPoint?.requiresPassword ?? accessPoint?.["requires-password"])
}

function isConnectingState(state: number) {
    return state >= AstalNetwork.DeviceState.PREPARE &&
        state < AstalNetwork.DeviceState.ACTIVATED
}

function runCommand(args: string[]) {
    return new Promise<string>((resolve, reject) => {
        let process: any

        try {
            process = Gio.Subprocess.new(
                args,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
            )
        } catch (error) {
            reject(error)
            return
        }

        process.communicate_utf8_async(null, null, (_process: unknown, result: unknown) => {
            try {
                const [, stdout, stderr] = process.communicate_utf8_finish(result)

                if (process.get_successful()) {
                    resolve(String(stdout ?? ""))
                    return
                }

                reject(new Error(String(stderr || stdout || `${args[0]} failed`)))
            } catch (error) {
                reject(error)
            }
        })
    })
}

function getErrorText(error: unknown) {
    return error instanceof Error ? error.message : String(error)
}

function needsPassword(error: unknown) {
    const message = getErrorText(error).toLowerCase()

    return message.includes("secrets were required") ||
        message.includes("no secrets provided") ||
        message.includes("password is required")
}

function connectArgs(accessPoint: AccessPoint, passwordValue = "") {
    const ssid = getAccessPointSsid(accessPoint)
    const bssid = getAccessPointBssid(accessPoint)
    const args = ["nmcli", "device", "wifi", "connect", ssid]

    if (passwordValue.length > 0) {
        args.push("password", passwordValue)
    }

    if (bssid.length > 0) {
        args.push("bssid", bssid)
    }

    return args
}

function sortAccessPoints(accessPoints: AccessPoint[], activeId: string) {
    const seen = new Set<string>()

    return [...accessPoints]
        .filter((accessPoint) => {
            const ssid = String(accessPoint.ssid ?? "").trim()

            if (!ssid || seen.has(ssid)) {
                return false
            }

            seen.add(ssid)
            return true
        })
        .sort((a, b) => {
            const aActive = Number(getAccessPointId(a) === activeId)
            const bActive = Number(getAccessPointId(b) === activeId)

            if (aActive !== bActive) {
                return bActive - aActive
            }

            return Number(b.strength ?? 0) - Number(a.strength ?? 0)
        })
}

async function activateAccessPoint(
    accessPoint: AccessPoint,
    passwordValue = "",
) {
    const id = getAccessPointId(accessPoint)
    const ssid = getAccessPointSsid(accessPoint)

    if (!ssid || connectingPath() === id) {
        return
    }

    setConnectionError("")
    setConnectingPath(id)

    try {
        await runCommand(connectArgs(accessPoint, passwordValue))
        closePasswordPrompt()
    } catch (error) {
        console.error("Network activation failed", error)

        if (passwordValue.length === 0 && needsPassword(error)) {
            setSelectedAccessPoint(accessPoint)
            setPassword("")
            setConnectionError("")
        } else {
            if (passwordValue.length > 0 || isSecureAccessPoint(accessPoint)) {
                setSelectedAccessPoint(accessPoint)
            }

            setConnectionError("Could not connect. Check the password and try again.")
        }
    } finally {
        setConnectingPath("")
    }
}

function toggleWifi(wifi: Wifi | null | undefined, enabled: boolean) {
    if (!wifi || wifi.enabled === enabled) {
        return
    }

    wifi.enabled = enabled
}

function scanWifi(wifi: Wifi | null | undefined) {
    if (!wifi?.enabled || wifi.scanning) {
        return
    }

    try {
        wifi.scan()
    } catch (error) {
        console.error("Wi-Fi scan failed", error)
    }
}

function NetworkHeader({
    wifi,
    enabled,
}: {
    wifi: Accessor<Wifi | null>
    enabled: Accessor<boolean>
}) {
    return (
        <box
            class="networkHeader"
            spacing={10}
        >
            <label
                class="networkPopoverTitle"
                label="Network"
                hexpand
                halign={Gtk.Align.START}
                xalign={0}
            />

            <switch
                class="networkSwitch"
                active={enabled}
                sensitive={wifi((value) => Boolean(value))}
                onNotifyActive={(sw) => toggleWifi(wifi(), sw.active)}
                $={(sw) => sw.set_cursor_from_name("pointer")}
            />
        </box>
    )
}

function StatusRow({
    icon,
    status,
}: {
    icon: Accessor<string>
    status: Accessor<string>
}) {
    return (
        <box
            class="networkStatus"
            spacing={8}
        >
            <BoxIcon
                name={icon}
                size={18}
                class="icon"
            />

            <label
                class="networkStatusText"
                label={status}
                ellipsize={Pango.EllipsizeMode.END}
                maxWidthChars={32}
                hexpand
                halign={Gtk.Align.START}
                xalign={0}
            />
        </box>
    )
}

function AccessPointRow({
    accessPoint,
    activeId,
    connecting,
}: {
    accessPoint: AccessPoint
    activeId: Accessor<string>
    connecting: Accessor<string>
}) {
    const ssid = createBinding(accessPoint, "ssid")
    const strength = createBinding(accessPoint, "strength")
    const requiresPassword = createBinding(accessPoint, "requires-password")
    const id = getAccessPointId(accessPoint)
    const isActive = activeId((value) => value === id)
    const isConnecting = connecting((value) => value === id)
    const icon = createComputed(() => signalIcon(Number(strength()) || 0, "wifi-0"))
    const meta = createComputed(() => {
        if (isConnecting()) return "Connecting"
        if (isActive()) return "Connected"
        if (requiresPassword()) return "Secured"
        return "Open"
    })
    const buttonClass = createComputed(() =>
        isActive()
            ? "popoverMenuAction networkAccessPointRow btnHovered"
            : "popoverMenuAction networkAccessPointRow",
    )

    return (
        <button
            class={buttonClass}
            onClicked={() => {
                if (isActive()) {
                    return
                }

                activateAccessPoint(accessPoint)
            }}
            $={(button) => button.set_cursor_from_name("pointer")}
        >
            <box
                spacing={10}
                hexpand
            >
                <BoxIcon
                    name={icon}
                    size={16}
                    class="networkAccessPointIcon icon"
                />

                <box
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={2}
                    hexpand
                    valign={Gtk.Align.CENTER}
                >
                    <label
                        class="networkAccessPointName"
                        label={ssid((value) => value || "Hidden network")}
                        ellipsize={Pango.EllipsizeMode.END}
                        maxWidthChars={25}
                        halign={Gtk.Align.START}
                        xalign={0}
                    />

                    <label
                        class="networkAccessPointMeta"
                        label={meta}
                        halign={Gtk.Align.START}
                        xalign={0}
                    />
                </box>

                <label
                    class="networkAccessPointStrength"
                    label={strength((value) => `${Math.round(Number(value) || 0)}%`)}
                    valign={Gtk.Align.CENTER}
                />

                <box visible={isConnecting}>
                    <BoxIcon
                        name="loader"
                        size={16}
                        class="networkAccessPointStateIcon icon"
                    />
                </box>

                <box visible={isActive}>
                    <BoxIcon
                        name="check"
                        size={16}
                        class="networkAccessPointStateIcon icon"
                    />
                </box>

                <box visible={createComputed(() => requiresPassword() && !isActive())}>
                    <BoxIcon
                        name="lock"
                        size={16}
                        class="networkAccessPointStateIcon icon"
                    />
                </box>
            </box>
        </button>
    )
}

function PasswordRow() {
    const selectedSsid = selectedAccessPoint((accessPoint) => accessPoint?.ssid ?? "")

    return (
        <box
            class="networkPasswordRow"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
            visible={selectedAccessPoint((accessPoint) => Boolean(accessPoint))}
        >
            <box spacing={8}>
                <label
                    class="networkPasswordLabel"
                    label={selectedSsid((ssid) => `Password for ${ssid}`)}
                    ellipsize={Pango.EllipsizeMode.END}
                    maxWidthChars={28}
                    hexpand
                    halign={Gtk.Align.START}
                    xalign={0}
                />

                <button
                    class="networkPasswordClose"
                    onClicked={() => {
                        closePasswordPrompt()
                    }}
                    $={(button) => button.set_cursor_from_name("pointer")}
                >
                    <BoxIcon
                        name="x"
                        size={14}
                        class="icon"
                    />
                </button>
            </box>

            <box spacing={8}>
                <entry
                    class="networkPasswordEntry"
                    visibility={showPassword}
                    text={password}
                    hexpand
                    onNotifyText={(entry) => setPassword(entry.text)}
                    onActivate={() => {
                        const accessPoint = selectedAccessPoint()

                        if (accessPoint && password().length > 0) {
                            activateAccessPoint(accessPoint, password())
                        }
                    }}
                />

                <button
                    class="networkPasswordToggle"
                    onClicked={() => setShowPassword((value) => !value)}
                    $={(button) => button.set_cursor_from_name("pointer")}
                >
                    <BoxIcon
                        name={showPassword((value) => value ? "eye-slash" : "eye")}
                        size={16}
                        class="icon"
                    />
                </button>

                <button
                    class="networkPasswordButton"
                    sensitive={password((value) => value.length > 0)}
                    onClicked={() => {
                        const accessPoint = selectedAccessPoint()

                        if (accessPoint) {
                            activateAccessPoint(accessPoint, password())
                        }
                    }}
                    $={(button) => button.set_cursor_from_name("pointer")}
                >
                    <BoxIcon
                        name="check"
                        size={16}
                        class="icon"
                    />
                </button>
            </box>

            <label
                class="networkPasswordError"
                label={connectionError}
                visible={connectionError((value) => value.length > 0)}
                wrap
                halign={Gtk.Align.START}
                xalign={0}
            />
        </box>
    )
}

export default function Network() {
    const wifi = createBinding(network, "wifi")
    const primary = createBinding(network, "primary")
    const state = createBinding(network, "state")
    const wifiEnabled = createBinding(network, "wifi", "enabled").as((value) => Boolean(value))
    const wifiSsid = createBinding(network, "wifi", "ssid").as((value) => String(value ?? ""))
    const wifiStrength = createBinding(network, "wifi", "strength").as((value) => Number(value) || 0)
    const wifiState = createBinding(network, "wifi", "state").as((value) => Number(value) || 0)
    const wifiScanning = createBinding(network, "wifi", "scanning").as((value) => Boolean(value))
    const wiredState = createBinding(network, "wired", "state").as((value) => Number(value) || 0)
    const activeAccessPoint = createBinding(network, "wifi", "active-access-point")
    const activeId = activeAccessPoint((accessPoint) => getAccessPointId(accessPoint))
    const accessPoints = createBinding(network, "wifi", "access-points").as((items) =>
        sortAccessPoints(Array.from(items ?? []) as AccessPoint[], activeId()),
    )
    const isWifiConnected = createComputed(() =>
        wifiState() === AstalNetwork.DeviceState.ACTIVATED && wifiSsid().length > 0,
    )
    const isWiredConnected = createComputed(() =>
        wiredState() === AstalNetwork.DeviceState.ACTIVATED ||
        primary() === AstalNetwork.Primary.WIRED,
    )
    const icon = createComputed(() => {
        if (isWiredConnected()) return "git-branch"
        if (isWifiConnected()) return signalIcon(wifiStrength())
        if (isConnectingState(wifiState()) || state() === AstalNetwork.State.CONNECTING) return "loader"
        return "wifi-slash"
    })
    const status = createComputed(() => {
        if (isWiredConnected()) return "Connected: Ethernet"
        if (isConnectingState(wifiState())) return "Connecting to Wi-Fi"
        if (isWifiConnected()) return `Connected: ${wifiSsid()}`
        if (!wifi()) return "No Wi-Fi device"
        if (!wifiEnabled()) return "Wi-Fi is off"
        if (wifiScanning()) return "Scanning for networks"
        return "Not connected"
    })
    const hasAccessPoints = accessPoints((items) => items.length > 0)

    return (
        <menubutton
            class="networkButton"
            $={(button) => {
                button.set_cursor_from_name("pointer")
                button.connect("notify::active", () => {
                    if (button.active) {
                        scanWifi(wifi())
                    } else {
                        closePasswordPrompt()
                    }
                })
            }}
        >
            <BoxIcon
                name={icon}
                size={18}
                class="icon"
            />

            <popover hasArrow={false}>
                <box
                    class="networkPopoverContent"
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={12}
                >
                    <NetworkHeader
                        wifi={wifi}
                        enabled={wifiEnabled}
                    />

                    <StatusRow
                        icon={icon}
                        status={status}
                    />

                    <label
                        class="networkError"
                        label={connectionError}
                        visible={createComputed(() =>
                            connectionError().length > 0 && !selectedAccessPoint(),
                        )}
                        wrap
                        halign={Gtk.Align.START}
                        xalign={0}
                    />

                    <PasswordRow />

                    <scrolledwindow
                        class="networkAccessPointScroller"
                        heightRequest={190}
                        hscrollbarPolicy={Gtk.PolicyType.NEVER}
                        vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                    >
                        <box
                            class="networkAccessPointRows"
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={6}
                        >
                            <For each={accessPoints}>
                                {(accessPoint) => (
                                    <AccessPointRow
                                        accessPoint={accessPoint}
                                        activeId={activeId}
                                        connecting={connectingPath}
                                    />
                                )}
                            </For>

                            <label
                                class="networkEmpty"
                                label={wifiEnabled((enabled) =>
                                    enabled ? "No networks found" : "Wi-Fi is off",
                                )}
                                visible={hasAccessPoints((value) => !value)}
                            />
                        </box>
                    </scrolledwindow>
                </box>
            </popover>
        </menubutton>
    )
}
