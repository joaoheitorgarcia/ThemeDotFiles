import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, For } from "gnim"

export default function Workspaces() {
    const hyprland = AstalHyprland.get_default()

    if (!hyprland) {
        return <box />
    }

    const workspaces = createBinding(hyprland, "workspaces").as((workspaces) =>
        Array.from(workspaces ?? [])
            .filter((workspace: any) => workspace.id === -98 || workspace.id > 0)
            .sort((a: any, b: any) => a.id - b.id),
    )

    const clients = createBinding(hyprland, "clients").as((clients) =>
        Array.from(clients ?? []) as any[],
    )

    const [activeWorkspaceId, setActiveWorkspaceId] = createState(0)
    const [activeAddress, setActiveAddress] = createState("")

    function refreshActiveWorkspaceId() {
        const client = clients().find((client: any) => client.address === activeAddress())

        if (client?.workspace?.id != null) {
            setActiveWorkspaceId(client.workspace.id)
            return
        }

        const specialWorkspaceId = hyprland.focusedMonitor?.specialWorkspace?.id ?? 0
        const workspaceId = hyprland.focusedWorkspace?.id ?? 0

        setActiveWorkspaceId(specialWorkspaceId < 0 ? specialWorkspaceId : workspaceId)
    }

    refreshActiveWorkspaceId()

    hyprland.connect("notify::clients", refreshActiveWorkspaceId)
    hyprland.connect("event", (_hyprland: any, event: string, data?: string) => {
        if (event === "activewindowv2" && data) {
            setActiveAddress(data.trim())
            refreshActiveWorkspaceId()
            return
        }

        if (event === "activespecial" || event === "workspace") {
            refreshActiveWorkspaceId()
        }
    })

    return (
        <box>
            <For each={workspaces}>
                {(workspace: any) => (
                    <button
                        class={activeWorkspaceId((id) =>
                            workspace.id === id
                                ? "workspaceBtn btnHovered"
                                : "workspaceBtn"
                        )}
                        $={(button) => button.set_cursor_from_name("pointer")}
                        onClicked={() => workspace.focus()}
                    >
                        <label label={workspace.id !== -98 ? String(workspace.id) : "S"} />
                    </button>
                )}
            </For>
        </box>
    )
}