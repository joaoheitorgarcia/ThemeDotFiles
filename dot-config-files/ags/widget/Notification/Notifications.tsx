import GLib from "gi://GLib?version=2.0"
import Gtk from "gi://Gtk?version=4.0"
import Pango from "gi://Pango?version=1.0"
import app from "ags/gtk4/app"
import { Astal, Gdk } from "ags/gtk4"
import { For, createComputed } from "gnim"
import BoxIcon from "../Common/BoxIcon"
import {
  clearAllNotificationPopups,
  dismissNotificationPopup,
  hasNotificationPopups,
  hiddenNotificationPopupCount,
  resolveNotificationSources,
  type NotificationEntry,
  visibleNotificationPopups,
} from "./NotificationState"

function setNotificationImage(image: Gtk.Image, item: NotificationEntry) {
  image.pixelSize = 32

  const iconTheme = image.get_display()
    ? Gtk.IconTheme.get_for_display(image.get_display()!)
    : null

  for (const source of resolveNotificationSources(item)) {
    if (GLib.path_is_absolute(source) && GLib.file_test(source, GLib.FileTest.EXISTS)) {
      image.set_from_file(source)
      image.visible = true
      return
    }

    if (iconTheme?.has_icon(source)) {
      image.set_from_icon_name(source)
      image.visible = true
      return
    }
  }

  image.visible = false
}

function NotificationPopupIcon({ item }: { item: NotificationEntry }) {
  const sources = resolveNotificationSources(item)

  if (sources.length === 0) {
    return (
      <box class="notificationPopupIconFallback">
        <BoxIcon
          name="bell"
          size={16}
          class="icon"
        />
      </box>
    )
  }

  return (
    <image
      class="notificationPopupIcon"
      $={(image) => setNotificationImage(image, item)}
    />
  )
}

function NotificationPopupCard({ item }: { item: NotificationEntry }) {
  return (
    <box
      class="notificationPopupCard"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
      $={(box) => {
        box.set_cursor_from_name("pointer")

        const click = Gtk.GestureClick.new()
        click.connect("released", () => dismissNotificationPopup(item.id))
        box.add_controller(click)
      }}
    >
      <box spacing={12}>
        <NotificationPopupIcon item={item} />

        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={4}
          hexpand
          valign={Gtk.Align.CENTER}
        >
          <label
            class="notificationPopupSummary"
            label={item.summary || "Notification"}
            ellipsize={Pango.EllipsizeMode.END}
            maxWidthChars={32}
            halign={Gtk.Align.START}
            xalign={0}
          />

          <label
            class="notificationPopupBody"
            label={item.body}
            wrap
            lines={4}
            maxWidthChars={36}
            halign={Gtk.Align.START}
            xalign={0}
            visible={Boolean(item.body)}
          />
        </box>
      </box>

      <Gtk.Separator
        orientation={Gtk.Orientation.HORIZONTAL}
        visible={Boolean(item.body)}
      />

      <label
        class="notificationPopupAppName"
        label={item.appName}
        ellipsize={Pango.EllipsizeMode.END}
        maxWidthChars={42}
        halign={Gtk.Align.START}
        xalign={0}
        visible={Boolean(item.appName)}
      />
    </box>
  )
}

function HiddenNotificationButton() {
  const isVisible = createComputed(() => hiddenNotificationPopupCount() > 0)
  const label = createComputed(() => {
    const count = hiddenNotificationPopupCount()
    return `+${count} more notification${count > 1 ? "s" : ""}`
  })

  return (
    <button
      class="notificationPopupHiddenCount"
      visible={isVisible}
      onClicked={clearAllNotificationPopups}
      $={(button) => button.set_cursor_from_name("pointer")}
    >
      <label label={label} />
    </button>
  )
}

export default function Notifications(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="notifications"
      class="Notifications"
      visible={hasNotificationPopups}
      $={(win) => {
        win.namespace = "ags-notifications"
        win.gdkmonitor = gdkmonitor
        win.exclusivity = Astal.Exclusivity.IGNORE
        win.keymode = Astal.Keymode.NONE
        win.anchor = TOP | RIGHT
        win.layer = Astal.Layer.OVERLAY
        win.marginTop = 52
        win.marginRight = 10
        win.application = app
      }}
    >
      <box
        class="notificationPopupWindow"
        orientation={Gtk.Orientation.VERTICAL}
        halign={Gtk.Align.END}
        valign={Gtk.Align.START}
      >
        <box
          class="notificationPopupColumn"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={10}
          halign={Gtk.Align.END}
        >
          <HiddenNotificationButton />

          <For each={visibleNotificationPopups}>
            {(item) => <NotificationPopupCard item={item} />}
          </For>
        </box>
      </box>
    </window>
  )
}
