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

    const [activeWorkspaceId, setActiveWorkspaceId] = createState(0)

    function refreshActiveWorkspaceId() {
        const focusedMonitor = hyprland.focusedMonitor
        const specialWorkspaceId = focusedMonitor?.specialWorkspace?.id ?? 0
        const focusedMonitorWorkspaceId =
            specialWorkspaceId < 0
                ? specialWorkspaceId
                : focusedMonitor?.activeWorkspace?.id

        setActiveWorkspaceId(focusedMonitorWorkspaceId ?? hyprland.focusedWorkspace?.id ?? 0)
    }

    refreshActiveWorkspaceId()

    hyprland.connect("notify::focused-monitor", refreshActiveWorkspaceId)
    hyprland.connect("notify::focused-workspace", refreshActiveWorkspaceId)
    hyprland.connect("event", (_hyprland: any, event: string) => {
        if (
            event === "activespecial" ||
            event === "workspace" ||
            event === "focusedmon" ||
            event === "moveworkspace" ||
            event === "createworkspace" ||
            event === "destroyworkspace"
        ) {
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
