import { Gtk } from "ags/gtk4"
import BoxIcon from "../Common/BoxIcon"
import { lock } from "../LockScreen"
import { runCommand } from "../Common/RunCommand"

type PowerAction = {
    id: string
    label: string
    icon: string
    command?: string[]
    action?: () => void
}

const actions: PowerAction[] = [
    { id: "lock", label: "Lock", icon: "lock", action: () => lock() },
    { id: "suspend", label: "Sleep", icon: "leaf", command: ["systemctl", "suspend"] },
    { id: "reboot", label: "Restart", icon: "redo", command: ["reboot"] },
    { id: "shutdown", label: "Shut Down", icon: "power", command: ["shutdown", "now"] },
]


export default function PowerActions() {
    let popover: Gtk.Popover | undefined

    return (
        <menubutton
            class="powerMenu"
            $={(button) => button.set_cursor_from_name("pointer")}
        >
            <BoxIcon
                name="power"
                size={18}
                class="icon"
            />
            <popover
                hasArrow={false}
            >
                <box
                    orientation={Gtk.Orientation.VERTICAL}
                    class="popoverContent"
                    spacing={6}
                >
                    {actions.map((action) => (
                        <button
                            $={(button) => button.set_cursor_from_name("pointer")}
                            class="popoverMenuAction"
                            onClicked={() => {
                                popover?.popdown()
                                if (action.action) {
                                    action.action()
                                    return
                                }

                                if (action.command) {
                                    runCommand(action.command)
                                }
                            }}
                        >
                            <box
                                spacing={10}
                                hexpand
                            >
                                <BoxIcon
                                    name={action.icon}
                                    size={16}
                                    class="icon"
                                />
                                <label
                                    label={action.label}
                                    hexpand
                                    halign={Gtk.Align.START}
                                />
                            </box>
                        </button>
                    ))}
                </box>
            </popover>
        </menubutton>
    )
}
