import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createConnection, For } from "gnim"

type Workspace = {
    id: number
    name?: string
}

type Monitor = {
    activeWorkspace?: Workspace | null
    specialWorkspace?: Workspace | null
}

function workspaceId(workspace: Workspace) {
    return Number(workspace.id) || 0
}

function specialWorkspaceName(workspace: Workspace) {
    return workspace.name?.replace(/^special:/, "") || "magic"
}

export default function Workspaces() {
    const hyprland = AstalHyprland.get_default()

    if (!hyprland) {
        return <box />
    }

    const workspaces = createBinding(hyprland, "workspaces").as((workspaces) =>
        (Array.from(workspaces ?? []) as Workspace[])
            .filter((workspace) => workspaceId(workspace) < 0 || workspaceId(workspace) > 0)
            .sort((a, b) => workspaceId(a) - workspaceId(b)),
    )

    function getActiveWorkspaceId() {
        const focusedMonitor = hyprland.focusedMonitor as Monitor | null
        const specialWorkspaceId = workspaceId(focusedMonitor?.specialWorkspace ?? { id: 0 })

        if (specialWorkspaceId < 0) {
            return specialWorkspaceId
        }

        return workspaceId(
            hyprland.focusedWorkspace ??
            focusedMonitor?.activeWorkspace ??
            { id: 0 },
        )
    }

    const activeWorkspaceId = createConnection(
        getActiveWorkspaceId(),
        [hyprland, "notify::focused-monitor", getActiveWorkspaceId],
        [hyprland, "event", getActiveWorkspaceId],
    )

    function focusWorkspace(id: number, specialName: string) {
        if (id > 0) {
            hyprland.dispatch("workspace", String(id))
        } else if (specialName.length > 0) {
            hyprland.dispatch("togglespecialworkspace", specialName)
        } else {
            hyprland.dispatch("togglespecialworkspace", "magic")
        }
    }

    return (
        <box>
            <For each={workspaces} id={(workspace) => workspaceId(workspace)}>
                {(workspace) => {
                    const id = workspaceId(workspace)
                    const specialName = specialWorkspaceName(workspace)

                    return (
                        <button
                            class={activeWorkspaceId((activeId) =>
                                id === activeId
                                    ? "workspaceBtn btnHovered"
                                    : "workspaceBtn"
                            )}
                            $={(button) => button.set_cursor_from_name("pointer")}
                            onClicked={() => focusWorkspace(id, specialName)}
                        >
                            <label label={id > 0 ? String(id) : "S"} />
                        </button>
                    )
                }}
            </For>
        </box>
    )
}
