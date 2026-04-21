import GLib from "gi://GLib?version=2.0"
import Gtk from "gi://Gtk?version=4.0"
import Pango from "gi://Pango?version=1.0"
import { For } from "gnim"
import BoxIcon from "../Common/BoxIcon"
import {
  clearAllNotificationPopups,
  clearNotificationHistory,
  type NotificationEntry,
  dismissNotificationHistoryItem,
  isNotificationHistoryEmpty,
  notificationHistory,
  resolveNotificationSources,
} from "../Notification/NotificationState"

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

function NotificationHistoryIcon({ item }: { item: NotificationEntry }) {
  const sources = resolveNotificationSources(item)

  if (sources.length === 0) {
    return (
      <box class="notificationHistoryIconFallback">
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
      class="notificationHistoryIcon"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      $={(image) => setNotificationImage(image, item)}
    />
  )
}

function NotificationHistoryRow({ item }: { item: NotificationEntry }) {
  return (
    <button
      class="notificationHistoryRow"
      hexpand
      onClicked={() => dismissNotificationHistoryItem(item.id)}
      $={(button) => button.set_cursor_from_name("pointer")}
    >
      <box
        spacing={12}
        hexpand
      >
        <NotificationHistoryIcon item={item} />

        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={4}
          hexpand
          valign={Gtk.Align.CENTER}
        >
          <label
            class="notificationHistorySummary"
            label={item.summary || "Notification"}
            ellipsize={Pango.EllipsizeMode.END}
            maxWidthChars={26}
            halign={Gtk.Align.START}
            xalign={0}
          />

          <label
            class="notificationHistoryAppName"
            label={item.appName}
            ellipsize={Pango.EllipsizeMode.END}
            maxWidthChars={28}
            halign={Gtk.Align.START}
            xalign={0}
            visible={Boolean(item.appName)}
          />
        </box>

        <BoxIcon
          name="x"
          size={16}
          class="notificationHistoryRemove icon"
        />
      </box>
    </button>
  )
}

export default function NotificationList() {
  return (
    <menubutton
      class="notificationListButton"
      $={(button) => {
        button.set_cursor_from_name("pointer")
        button.connect("notify::active", () => {
          if (button.active) {
            clearAllNotificationPopups()
          }
        })
      }}
    >
      <BoxIcon
        name="bell"
        size={18}
        class="icon"
      />

      <popover
        class="notificationListPopover"
        hasArrow={false}
      >
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={12}
          class="notificationListContent"
        >
          <box
            class="notificationListHeader"
            spacing={8}
          >
            <label
              class="notificationListTitle"
              label="Notification History"
              hexpand
              halign={Gtk.Align.START}
              xalign={0}
            />

            <button
              class="notificationHistoryClear"
              label="Dismiss all"
              visible={notificationHistory((items) => items.length > 0)}
              onClicked={clearNotificationHistory}
              $={(button) => button.set_cursor_from_name("pointer")}
            />
          </box>

          <scrolledwindow
            class="notificationListScroller"
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
            vexpand
          >
            <box
              orientation={Gtk.Orientation.VERTICAL}
              spacing={6}
              class="notificationListRows"
            >
              <For each={notificationHistory}>
                {(item) => <NotificationHistoryRow item={item} />}
              </For>

              <label
                class="notificationHistoryEmpty"
                label="No new notification"
                visible={isNotificationHistoryEmpty}
                justify={Gtk.Justification.CENTER}
              />
            </box>
          </scrolledwindow>
        </box>
      </popover>
    </menubutton>
  )
}
