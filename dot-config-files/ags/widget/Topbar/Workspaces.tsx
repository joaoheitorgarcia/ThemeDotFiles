import AstalHyprland from "gi://AstalHyprland"
import { createBinding, For } from "gnim"

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

    return (
        <box>
            <For each={workspaces}>
                {(workspace: any) => (
                    <button
                        class="workspaceBtn"
                        $={(button) => button.set_cursor_from_name("pointer")}
                        onClicked={() => workspace.focus()}>
                        <label label={workspace.id !== -98 ? String(workspace.id) : "S"} />
                    </button>
                )}
            </For>
        </box>
    )
}
