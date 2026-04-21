import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import GioUnix from "gi://GioUnix?version=2.0"
import AstalNotifd from "gi://AstalNotifd"
import { createComputed, createState } from "gnim"

export type NotificationEntry = {
  id: number
  notificationId: number
  summary: string
  body: string
  appName: string
  appIcon: string
  desktopEntry: string
  image: string
  urgency: number
}

const LOW_URGENCY = 0
const CRITICAL_URGENCY = 2
const POPUP_TIMEOUT_MS = 5000
const CRITICAL_POPUP_TIMEOUT_MS = 10000
const MAX_VISIBLE_POPUPS = 3
const DEFAULT_CRITICAL_SOUND = "dialog-warning"

export const notifd = AstalNotifd.Notifd?.get_default?.() ?? AstalNotifd.get_default?.()

const [notificationHistory, setNotificationHistory] = createState<NotificationEntry[]>([])
const [notificationPopups, setNotificationPopups] = createState<NotificationEntry[]>([])

export { notificationHistory, notificationPopups }

export const isNotificationHistoryEmpty = createComputed(
  () => notificationHistory().length === 0,
)

export const hasNotificationPopups = createComputed(
  () => notificationPopups().length > 0,
)

export const visibleNotificationPopups = createComputed(
  () => notificationPopups().slice(0, MAX_VISIBLE_POPUPS),
)

export const hiddenNotificationPopupCount = createComputed(
  () => Math.max(0, notificationPopups().length - MAX_VISIBLE_POPUPS),
)

let notificationEntryId = 0
const popupTimeouts = new Map<number, number>()

function snapshotNotification(notification: any): NotificationEntry {
  return {
    id: ++notificationEntryId,
    notificationId: Number(notification.id ?? 0),
    summary: String(notification.summary ?? "").trim(),
    body: String(notification.body ?? "").trim(),
    appName: String(notification.appName ?? notification.app_name ?? "").trim(),
    appIcon: String(notification.appIcon ?? notification.app_icon ?? "").trim(),
    desktopEntry: String(notification.desktopEntry ?? notification.desktop_entry ?? "").trim(),
    image: String(notification.image ?? "").trim(),
    urgency: Number(notification.urgency ?? 1),
  }
}

function resolveDesktopEntryIcon(desktopEntry: string) {
  if (!desktopEntry) {
    return ""
  }

  const desktopId = desktopEntry.endsWith(".desktop")
    ? desktopEntry
    : `${desktopEntry}.desktop`

  try {
    const appInfo = GioUnix.DesktopAppInfo.new(desktopId)
    const icon = appInfo?.get_icon?.()

    if (icon instanceof Gio.ThemedIcon) {
      const names = icon.get_names?.() ?? []
      return String(names[0] ?? "").trim()
    }

    return String(icon?.to_string?.() ?? "").trim()
  } catch (error) {
    console.error(`Failed to resolve desktop entry icon for ${desktopId}`, error)
    return ""
  }
}

function normalizedAppIconName(appName: string) {
  return appName
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
}

function clearPopupTimeout(id: number) {
  const sourceId = popupTimeouts.get(id)

  if (sourceId === undefined) {
    return
  }

  GLib.source_remove(sourceId)
  popupTimeouts.delete(id)
}

function queuePopup(entry: NotificationEntry) {
  setNotificationPopups((items) => [...items, entry])

  const timeout = entry.urgency === CRITICAL_URGENCY
    ? CRITICAL_POPUP_TIMEOUT_MS
    : POPUP_TIMEOUT_MS

  const sourceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
    popupTimeouts.delete(entry.id)
    dismissNotificationPopup(entry.id, false)
    return GLib.SOURCE_REMOVE
  })

  popupTimeouts.set(entry.id, sourceId)
}

function playCriticalNotificationSound(notification: any) {
  if (Number(notification.urgency ?? 1) !== CRITICAL_URGENCY) {
    return
  }

  if (Boolean(notification.suppressSound ?? notification.suppress_sound)) {
    return
  }

  const soundFile = String(notification.soundFile ?? notification.sound_file ?? "").trim()
  const soundName = String(notification.soundName ?? notification.sound_name ?? "").trim()

  const command = soundFile
    ? ["canberra-gtk-play", "-f", soundFile]
    : ["canberra-gtk-play", "-i", soundName || DEFAULT_CRITICAL_SOUND]

  try {
    Gio.Subprocess.new(
      command,
      Gio.SubprocessFlags.STDOUT_SILENCE |
        Gio.SubprocessFlags.STDERR_SILENCE,
    )
  } catch (error) {
    console.error("Failed to play critical notification sound", error)
  }
}

if (notifd) {
  notifd.connect("notified", (_self: unknown, id: number) => {
    const notification = notifd.get_notification?.(id)

    if (!notification) {
      return
    }

    playCriticalNotificationSound(notification)

    const entry = snapshotNotification(notification)

    if (entry.urgency !== LOW_URGENCY) {
      setNotificationHistory((items) => [...items, entry])
    }

    queuePopup(entry)
  })

  notifd.connect("resolved", (_self: unknown, id: number) => {
    setNotificationPopups((items) => {
      const removedIds = items
        .filter((item) => item.notificationId === id)
        .map((item) => item.id)

      removedIds.forEach(clearPopupTimeout)

      return items.filter((item) => item.notificationId !== id)
    })
  })
}

export function resolveNotificationSources(entry: NotificationEntry) {
  return [
    entry.appIcon,
    resolveDesktopEntryIcon(entry.desktopEntry),
    entry.appName,
    normalizedAppIconName(entry.appName),
    entry.image,
  ].filter((source, index, items) => Boolean(source) && items.indexOf(source) === index)
}

export function dismissNotificationPopup(id: number, clearTimer = true) {
  if (clearTimer) {
    clearPopupTimeout(id)
  }

  setNotificationPopups((items) => items.filter((item) => item.id !== id))
}

export function dismissNotificationHistoryItem(id: number) {
  setNotificationHistory((items) => items.filter((item) => item.id !== id))
}

export function clearNotificationHistory() {
  setNotificationHistory([])
}

export function clearAllNotificationPopups() {
  popupTimeouts.forEach((sourceId) => GLib.source_remove(sourceId))
  popupTimeouts.clear()
  setNotificationPopups([])
}
