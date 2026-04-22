import GLib from "gi://GLib?version=2.0"
import AstalApps from "gi://AstalApps"
import Pango from "gi://Pango?version=1.0"
import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createComputed, createEffect, createState, For, type Accessor } from "gnim"

type Application = any

const applications = new AstalApps.Apps()

const [allApplications, setAllApplications] = createState<Application[]>([])
const [query, setQuery] = createState("")
const [selectedIndex, setSelectedIndex] = createState(0)

let searchEntry: Gtk.Entry | null = null
let appMenuFrame: Gtk.CenterBox | null = null

function appList() {
  return Array.from(applications.list ?? []) as Application[]
}

function appText(application: Application, key: string) {
  return String(application?.[key] ?? "").trim()
}

function filterApplications(items: Application[], search: string) {
  const normalizedSearch = search.trim().toLowerCase()

  if (normalizedSearch.length === 0) {
    return items
  }

  return items
    .map((application) => {
      const name = appText(application, "name")
      const description = appText(application, "description")
      const executable = appText(application, "executable")

      const nameLower = name.toLowerCase()
      const descriptionLower = description.toLowerCase()
      const executableLower = executable.toLowerCase()

      const exactName = nameLower === normalizedSearch
      const exactDescription = descriptionLower === normalizedSearch
      const exactExecutable = executableLower === normalizedSearch

      const containsName = nameLower.includes(normalizedSearch)
      const containsDescription = descriptionLower.includes(normalizedSearch)
      const containsExecutable = executableLower.includes(normalizedSearch)

      return {
        application,
        exactName,
        exactDescription,
        exactExecutable,
        containsName,
        containsDescription,
        containsExecutable,
        sortKey: nameLower || descriptionLower || executableLower,
      }
    })
    .filter((item) =>
      item.exactName ||
      item.exactDescription ||
      item.exactExecutable ||
      item.containsName ||
      item.containsDescription ||
      item.containsExecutable,
    )
    .sort((a, b) => {
      if (a.exactName !== b.exactName) return a.exactName ? -1 : 1
      if (a.exactDescription !== b.exactDescription) return a.exactDescription ? -1 : 1
      if (a.exactExecutable !== b.exactExecutable) return a.exactExecutable ? -1 : 1
      if (a.containsName !== b.containsName) return a.containsName ? -1 : 1
      if (a.containsDescription !== b.containsDescription) return a.containsDescription ? -1 : 1
      if (a.containsExecutable !== b.containsExecutable) return a.containsExecutable ? -1 : 1
      return a.sortKey.localeCompare(b.sortKey)
    })
    .map((item) => item.application)
}

const filteredApplications = createComputed(() => filterApplications(allApplications(), query()))
const selectedApplication = createComputed(() => filteredApplications()[selectedIndex()] ?? null)
const hasApplications = filteredApplications((items) => items.length > 0)

function refreshApplications() {
  applications.reload()
  setAllApplications(appList())
}

function focusSearch() {
  GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
    searchEntry?.grab_focus()
    return GLib.SOURCE_REMOVE
  })
}

function openMenu() {
  refreshApplications()
  setQuery("")
  setSelectedIndex(0)
  focusSearch()
}

function closeMenu() {
  const window = app.get_window("appmenu")

  if (window) {
    window.visible = false
  }
}

function syncToFocusedMonitor(window: any, fallback: Gdk.Monitor) {
  const geometry = fallback.get_geometry()

  window.gdkmonitor = fallback
  window.set_default_size(geometry.width, geometry.height)

  if (appMenuFrame) {
    appMenuFrame.widthRequest = geometry.width
    appMenuFrame.heightRequest = geometry.height
  }
}

function launchApplication(application: Application | null | undefined) {
  if (!application) {
    return
  }

  closeMenu()

  try {
    application.launch()
  } catch (error) {
    console.error("Failed to launch application", error)
  }
}

function setApplicationIcon(image: Gtk.Image, application: Application) {
  image.pixelSize = 30

  const iconName = appText(application, "iconName") || appText(application, "icon_name")
  const iconTheme = image.get_display()
    ? Gtk.IconTheme.get_for_display(image.get_display()!)
    : null

  if (iconName && GLib.path_is_absolute(iconName) && GLib.file_test(iconName, GLib.FileTest.EXISTS)) {
    image.set_from_file(iconName)
    return
  }

  if (iconName && iconTheme?.has_icon(iconName)) {
    image.set_from_icon_name(iconName)
    return
  }

  image.set_from_icon_name("application-x-executable")
}

function moveSelection(delta: number) {
  const count = filteredApplications().length

  if (count === 0) {
    setSelectedIndex(-1)
    return
  }

  setSelectedIndex((index) => {
    const next = index + delta

    if (next < 0) return count - 1
    if (next >= count) return 0
    return next
  })
}

function handleKey(keyval: number) {
  switch (keyval) {
    case Gdk.KEY_Up:
      moveSelection(-1)
      return true
    case Gdk.KEY_Down:
      moveSelection(1)
      return true
    case Gdk.KEY_Return:
    case Gdk.KEY_KP_Enter:
      launchApplication(selectedApplication())
      return true
    case Gdk.KEY_Escape:
      closeMenu()
      return true
    default:
      return false
  }
}

function ApplicationRow({
  application,
  selected,
}: {
  application: Application
  selected: Accessor<Application | null>
}) {
  const name = appText(application, "name") || "Unknown App"
  const description = appText(application, "description") || appText(application, "executable")
  const isSelected = selected((value) => value === application)

  return (
    <button
      class={isSelected((value) =>
        value ? "appMenuRow appMenuRowSelected" : "appMenuRow",
      )}
      onClicked={() => launchApplication(application)}
      $={(button) => button.set_cursor_from_name("pointer")}
    >
      <box spacing={10}>
        <image
          class="appMenuIcon"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          $={(image) => setApplicationIcon(image, application)}
        />

        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={3}
          hexpand
          valign={Gtk.Align.CENTER}
        >
          <label
            class="appMenuAppName"
            label={name}
            ellipsize={Pango.EllipsizeMode.END}
            maxWidthChars={34}
            halign={Gtk.Align.START}
            xalign={0}
          />

          <label
            class="appMenuAppDescription"
            label={description}
            visible={description.length > 0}
            ellipsize={Pango.EllipsizeMode.END}
            maxWidthChars={38}
            halign={Gtk.Align.START}
            xalign={0}
          />
        </box>
      </box>
    </button>
  )
}

function AppMenuPanel() {
  return (
    <box
      class="appMenuPanel"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={10}
      widthRequest={450}
      heightRequest={250}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <entry
        class="appMenuSearch"
        placeholderText="Search apps..."
        text={query}
        onNotifyText={(entry) => {
          setQuery(entry.text)
          setSelectedIndex(0)
        }}
        onActivate={() => launchApplication(selectedApplication())}
        $={(entry) => {
          searchEntry = entry
        }}
      />

      <scrolledwindow
        class="appMenuScroller"
        hscrollbarPolicy={Gtk.PolicyType.NEVER}
        vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
        vexpand
      >
        <box
          class="appMenuRows"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={6}
        >
          <For each={filteredApplications}>
            {(application) => (
              <ApplicationRow
                application={application}
                selected={selectedApplication}
              />
            )}
          </For>

          <label
            class="appMenuEmpty"
            label="No apps found"
            visible={hasApplications((value) => !value)}
          />
        </box>
      </scrolledwindow>
    </box>
  ) as Gtk.Widget
}

export default function AppMenu(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const geometry = gdkmonitor.get_geometry()

  createEffect(() => {
    const count = filteredApplications().length
    const currentIndex = selectedIndex()

    if (count === 0 && currentIndex !== -1) {
      setSelectedIndex(-1)
    } else if (count > 0 && (currentIndex < 0 || currentIndex >= count)) {
      setSelectedIndex(0)
    }
  })

  return (
    <window
      name="appmenu"
      class="AppMenu"
      visible={false}
      decorated={false}
      resizable={false}
      canFocus
      $={(window) => {
        window.namespace = "ags-appmenu"
        window.gdkmonitor = gdkmonitor
        window.set_default_size(geometry.width, geometry.height)
        window.exclusivity = Astal.Exclusivity.IGNORE
        window.keymode = Astal.Keymode.EXCLUSIVE
        window.anchor = TOP | LEFT | RIGHT | BOTTOM
        window.layer = Astal.Layer.OVERLAY
        window.application = app

        const keyController = Gtk.EventControllerKey.new()
        keyController.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        keyController.connect("key-pressed", (_controller, keyval) => handleKey(keyval))
        window.add_controller(keyController)

        window.connect("notify::visible", () => {
          if (window.visible) {
            syncToFocusedMonitor(window, gdkmonitor)
            openMenu()
          }
        })
      }}
    >
      <centerbox
        class="appMenuOverlay"
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={geometry.width}
        heightRequest={geometry.height}
        hexpand
        vexpand
        halign={Gtk.Align.FILL}
        valign={Gtk.Align.FILL}
        $={(centerbox) => {
          appMenuFrame = centerbox
          centerbox.set_center_widget(AppMenuPanel())
        }}
      />
    </window>
  )
}
