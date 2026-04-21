import GLib from "gi://GLib?version=2.0"
import { Gtk } from "ags/gtk4"
import BoxIcon from "../Common/BoxIcon"
import { runCommand } from "../Common/RunCommand"

type IdleState = "enabled" | "disabled" | "unknown"

function refreshIdleState(
  enabledIcon: Gtk.Widget,
  disabledIcon: Gtk.Widget,
  button: Gtk.Button,
) {
  runCommand(
    [
      "sh",
      "-c",
      "pgrep -u \"$(id -u)\" -x hypridle >/dev/null && printf enabled || printf disabled",
    ],
    (stdout) => {
      const state: IdleState = stdout.trim() === "enabled" ? "enabled" : "disabled"
      const enabled = state === "enabled"

      enabledIcon.visible = enabled
      disabledIcon.visible = !enabled
      button.tooltipText = enabled ? "Auto lock enabled" : "Auto lock disabled"
      button.sensitive = true
    },
  )
}

function toggleIdleState(
  enabledIcon: Gtk.Widget,
  disabledIcon: Gtk.Widget,
  button: Gtk.Button,
) {
  const enabling = !enabledIcon.visible
  const command = enabling
    ? "nohup hypridle -q >/dev/null 2>&1 &"
    : "pkill -u \"$(id -u)\" -x hypridle"

  button.sensitive = false

  runCommand(["sh", "-c", command], () => {
    runCommand(
      [
        "notify-send",
        "-a",
        "AGS",
        "Auto lock/suspend",
        enabling ? "Enabled" : "Disabled",
      ],
    )
    refreshIdleState(enabledIcon, disabledIcon, button)
  })
}

export default function LockToggle() {
  let button: Gtk.Button | undefined
  let enabledIcon: Gtk.Widget | undefined
  let disabledIcon: Gtk.Widget | undefined

  const refresh = () => {
    if (!button || !enabledIcon || !disabledIcon) {
      return
    }

    refreshIdleState(enabledIcon, disabledIcon, button)
  }

  return (
    <button
      $={(widget) => {
        button = widget
        widget.set_cursor_from_name("pointer")
        widget.tooltipText = "Checking auto lock state"

        GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
          refresh()
          return GLib.SOURCE_REMOVE
        })

        const motion = new Gtk.EventControllerMotion()
        motion.connect("enter", refresh)
        widget.add_controller(motion)

        const focus = new Gtk.EventControllerFocus()
        focus.connect("enter", refresh)
        widget.add_controller(focus)
      }}
      onClicked={() => {
        if (button && enabledIcon && disabledIcon) {
          toggleIdleState(enabledIcon, disabledIcon, button)
        }
      }}
    >
      <box>
        <BoxIcon
          name="lock"
          size={18}
          class="icon"
          $={(widget: any) => {
            enabledIcon = widget
            widget.visible = false
          }}
        />
        <BoxIcon
          name="lock-open"
          size={18}
          class="icon"
          $={(widget: any) => {
            disabledIcon = widget
            widget.visible = false
          }}
        />
      </box>
    </button>
  )
}
