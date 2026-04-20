import Gio from "gi://Gio?version=2.0"
import GLib from "gi://GLib?version=2.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalAuth from "gi://AstalAuth?version=0.1"
import Gtk4SessionLock from "gi://Gtk4SessionLock?version=1.0"
import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import BoxIcon from "./Common/BoxIcon"

const wallpaperFile = Gio.File.new_for_path(
  `${SRC}/assets/background-images/car-sunset.png`,
)

const sessionLock = new Gtk4SessionLock.Instance()
const pam = new AstalAuth.Pam()

type SurfaceState = {
  window: Gtk.Window
  timeLabel: Gtk.Label
  dateLabel: Gtk.Label
  entry: Gtk.PasswordEntry
  button: Gtk.Button
  messageLabel: Gtk.Label
  isPrimary: boolean
}

type SurfaceRefs = Partial<Omit<SurfaceState, "isPrimary">> & {
  isPrimary: boolean
}

type LockSurfaceProps = {
  refs: SurfaceRefs
  onPasswordChanged: (entry: Gtk.PasswordEntry) => void
  onUnlock: () => void
}

const surfaces = new Set<SurfaceState>()

let activeSurface: SurfaceState | null = null
let password = ""
let authenticating = false
let clockSourceId = 0
let setupComplete = false

function requireRef<T>(value: T | undefined, name: string): T {
  if (value === undefined) {
    throw Error(`Lock screen ref "${name}" was not initialized`)
  }

  return value
}

function LockSurface({ refs, onPasswordChanged, onUnlock }: LockSurfaceProps) {
  const background = (
    <Gtk.Picture
      class="lockScreenWallpaper"
      file={wallpaperFile}
      hexpand
      vexpand
      canShrink
      contentFit={Gtk.ContentFit.COVER}
    />
  ) as Gtk.Picture

  const dimmer = (
    <box
      class="lockScreenDim"
      hexpand
      vexpand
    />
  ) as Gtk.Box

  const content = (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      hexpand
      vexpand
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <box
        class="lockScreenCard"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={12}
        widthRequest={360}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        marginTop={20}
        marginBottom={20}
        marginStart={20}
        marginEnd={20}
      >
        <box
          orientation={Gtk.Orientation.HORIZONTAL}
          spacing={10}
          hexpand
        >
          <BoxIcon
            name="lock"
            size={18}
            class="icon"
          />

          <label
            class="lockScreenTitle"
            label="Session locked"
            hexpand
            halign={Gtk.Align.START}
            xalign={0}
          />
        </box>

        <label
          class="lockScreenTime"
          halign={Gtk.Align.CENTER}
          xalign={0.5}
          $={(label) => {
            refs.timeLabel = label
          }}
        />

        <label
          class="lockScreenDate"
          halign={Gtk.Align.CENTER}
          xalign={0.5}
          $={(label) => {
            refs.dateLabel = label
          }}
        />

        <Gtk.Separator
          orientation={Gtk.Orientation.HORIZONTAL}
          marginTop={4}
          marginBottom={4}
        />

        <Gtk.PasswordEntry
          class="lockScreenEntry"
          placeholderText="Password"
          activatesDefault
          showPeekIcon={false}
          $={(entry) => {
            refs.entry = entry
            entry.connect("changed", () => onPasswordChanged(entry))
            entry.connect("activate", onUnlock)
          }}
        />

        <button
          class="lockScreenButton"
          label="Unlock"
          halign={Gtk.Align.FILL}
          hexpand
          onClicked={onUnlock}
          $={(button) => {
            refs.button = button
            button.add_css_class("suggested-action")
          }}
        />

        <label
          class="lockScreenMessage"
          visible={false}
          wrap
          justify={Gtk.Justification.CENTER}
          halign={Gtk.Align.CENTER}
          xalign={0.5}
          $={(label) => {
            refs.messageLabel = label
          }}
        />
      </box>
    </box>
  ) as Gtk.Box

  return (
    <window
      name="lock-screen"
      class="LockScreen"
      decorated={false}
      deletable={false}
      resizable
      canFocus
      $={(window) => {
        refs.window = window
      }}
    >
      <overlay
        hexpand
        vexpand
        $={(overlay) => {
          overlay.set_child(background)
          overlay.add_overlay(dimmer)
          overlay.add_overlay(content)
        }}
      />
    </window>
  )
}

function formatClock() {
  const now = GLib.DateTime.new_now_local()

  return {
    time: now?.format("%H:%M") ?? "",
    date: now?.format("%A, %d %B") ?? "",
  }
}

function updateClock() {
  const { time, date } = formatClock()

  for (const surface of surfaces) {
    surface.timeLabel.label = time
    surface.dateLabel.label = date
  }
}

function ensureClock() {
  if (clockSourceId !== 0) {
    return
  }

  updateClock()
  clockSourceId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
    updateClock()
    return GLib.SOURCE_CONTINUE
  })
}

function stopClock() {
  if (clockSourceId === 0) {
    return
  }

  GLib.source_remove(clockSourceId)
  clockSourceId = 0
}

function syncEntries(source?: Gtk.PasswordEntry) {
  for (const surface of surfaces) {
    if (surface.entry !== source && surface.entry.text !== password) {
      surface.entry.text = password
    }
  }
}

function focusActiveEntry() {
  const surface =
    activeSurface ??
    [...surfaces].find((item) => item.isPrimary) ??
    [...surfaces][0]

  if (!surface) {
    return
  }

  activeSurface = surface
  GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
    surface.entry.grab_focus()
    return GLib.SOURCE_REMOVE
  })
}

function setMessage(message: string, isError = false) {
  for (const surface of surfaces) {
    surface.messageLabel.label = message
    surface.messageLabel.visible = message.length > 0

    if (isError) {
      surface.messageLabel.add_css_class("error")
    } else {
      surface.messageLabel.remove_css_class("error")
    }
  }
}

function updateAuthUi() {
  for (const surface of surfaces) {
    surface.entry.sensitive = !authenticating
    surface.button.sensitive = !authenticating && password.length > 0
    surface.button.label = authenticating ? "Unlocking..." : "Unlock"
  }
}

function resetState() {
  password = ""
  authenticating = false
  syncEntries()
  setMessage("")
  updateAuthUi()
}

function handlePasswordChanged(entry: Gtk.PasswordEntry) {
  const next = entry.text

  if (next === password) {
    return
  }

  password = next
  setMessage("")
  syncEntries(entry)
  updateAuthUi()
}

function tryUnlock() {
  if (authenticating || password.length === 0) {
    return
  }

  authenticating = true
  setMessage("")
  updateAuthUi()

  if (!pam.start_authenticate()) {
    authenticating = false
    setMessage("Authentication could not be started.", true)
    updateAuthUi()
    focusActiveEntry()
  }
}

function buildSurfaceWindow(isPrimary: boolean) {
  const refs: SurfaceRefs = { isPrimary }
  const window = LockSurface({
    refs,
    onPasswordChanged: handlePasswordChanged,
    onUnlock: tryUnlock,
  }) as Gtk.Window

  const state: SurfaceState = {
    window: refs.window ?? window,
    timeLabel: requireRef(refs.timeLabel, "timeLabel"),
    dateLabel: requireRef(refs.dateLabel, "dateLabel"),
    entry: requireRef(refs.entry, "entry"),
    button: requireRef(refs.button, "button"),
    messageLabel: requireRef(refs.messageLabel, "messageLabel"),
    isPrimary,
  }

  state.window.connect("destroy", () => {
    surfaces.delete(state)

    if (activeSurface === state) {
      activeSurface = null
    }
  })

  surfaces.add(state)

  if (isPrimary || activeSurface === null) {
    activeSurface = state
  }

  return state
}

function ensureSetup() {
  if (setupComplete) {
    return
  }

  setupComplete = true

  pam.connect("auth-prompt-hidden", () => {
    pam.supply_secret(password)
  })

  pam.connect("auth-prompt-visible", () => {
    pam.supply_secret(password)
  })

  pam.connect("auth-info", (_pam: never, message: string) => {
    setMessage(message)
    pam.supply_secret(null)
  })

  pam.connect("auth-error", (_pam: never, message: string) => {
    setMessage(message, true)
    pam.supply_secret(null)
  })

  pam.connect("fail", (_pam: never, message: string) => {
    authenticating = false
    password = ""
    syncEntries()
    setMessage(message || "Wrong password.", true)
    updateAuthUi()
    focusActiveEntry()
  })

  pam.connect("success", () => {
    authenticating = false
    updateAuthUi()
    sessionLock.unlock()
  })

  sessionLock.connect("monitor", (_instance: never, monitor: Gdk.Monitor) => {
    const state = buildSurfaceWindow(surfaces.size === 0)

    app.add_window(state.window)
    sessionLock.assign_window_to_monitor(state.window, monitor)
    updateClock()
    updateAuthUi()
    focusActiveEntry()
  })

  sessionLock.connect("locked", () => {
    resetState()
    ensureClock()
    focusActiveEntry()
  })

  sessionLock.connect("unlocked", () => {
    resetState()
    stopClock()

    for (const surface of [...surfaces]) {
      surface.window.destroy()
    }

    surfaces.clear()
    activeSurface = null
  })

  sessionLock.connect("failed", () => {
    stopClock()
    setMessage("Session lock failed.", true)
    console.error("Failed to acquire the session lock.")
  })
}

export function lock() {
  ensureSetup()

  if (sessionLock.is_locked()) {
    focusActiveEntry()
    return true
  }

  if (!Gtk4SessionLock.is_supported()) {
    console.error("Gtk4SessionLock is not supported on this compositor.")
    return false
  }

  resetState()
  return sessionLock.lock()
}
