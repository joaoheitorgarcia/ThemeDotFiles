import { Gtk } from "ags/gtk4"
import { createExternal } from "gnim"
import GLib from "gi://GLib?version=2.0"

function formatTime() {
    return GLib.DateTime.new_now_local()?.format("%H:%M") ?? ""
}

const time = createExternal(formatTime(), (set) => {
    const sourceId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
        set(formatTime())
        return GLib.SOURCE_CONTINUE
    })
    return () => GLib.source_remove(sourceId)
})

export default function DateTime() {
    return (
        <menubutton
            $type="end"
            $={(button) => button.set_cursor_from_name("pointer")}
        >
            <label label={time} />
            <popover>
                <Gtk.Calendar />
            </popover>
        </menubutton>
    )
}
