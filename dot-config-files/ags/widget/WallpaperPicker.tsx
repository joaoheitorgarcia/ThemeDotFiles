import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"
import GdkPixbuf from "gi://GdkPixbuf?version=2.0"
import Pango from "gi://Pango?version=1.0"
import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createComputed, createState, For } from "gnim"
import {
  currentBackgroundPath,
  listBackgrounds,
  selectBackground,
  type BackgroundEntry,
} from "./Common/BackgroundState"

const [backgrounds, setBackgrounds] = createState<BackgroundEntry[]>([])
const [selectedIndex, setSelectedIndex] = createState(0)
const selectedBackground = createComputed(() => backgrounds()[selectedIndex()] ?? null)
const indexedBackgrounds = createComputed(() =>
  backgrounds().map((entry, index) => ({ ...entry, index })),
)

let wallpaperScroller: Gtk.ScrolledWindow | null = null

function refreshBackgrounds() {
  const entries = listBackgrounds()
  const currentPath = currentBackgroundPath()
  const currentIndex = entries.findIndex((entry) => entry.path === currentPath)

  setBackgrounds(entries)
  setSelectedIndex(currentIndex >= 0 ? currentIndex : entries.length > 0 ? 0 : -1)
  scrollSelectionIntoView(currentIndex >= 0 ? currentIndex : 0)
}

function closePicker() {
  const window = app.get_window("wallpaperpicker")

  if (window) {
    window.visible = false
  }
}

export function toggleWallpaperPicker() {
  const window = app.get_window("wallpaperpicker")

  if (window) {
    window.visible = !window.visible
  }
}

function applyBackground(entry: BackgroundEntry | null | undefined) {
  if (!entry) {
    return
  }

  const mode = pickMatugenMode(entry.path)

  selectBackground(entry)
  closePicker()
  runMatugen(entry.path, mode)
}

function restartAgs() {
  GLib.spawn_command_line_async("sh -lc 'sleep 0.2; ags run ~/.config/ags/app.ts'")
  app.quit()
}

function runMatugen(path: string, mode: "light" | "dark") {
  const command = ["matugen", "image", path, "-m", mode, "--prefer", "lightness"]
  // prefer modes for matugen:
  // - saturation: picks the most vivid / colorful candidate.
  // - less-saturation: picks a more muted / neutral candidate.
  // - darkness: prefers darker candidate colors.
  // - lightness: prefers lighter candidate colors.
  // - value: prefers colors with higher HSV “value”, usually brighter / stronger - looking colors.
  // - closest-to-fallback: picks the candidate closest to your configured fallback color.


  try {
    const process = Gio.Subprocess.new(
      command,
      Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
    )

    process.communicate_utf8_async(null, null, (_process, result) => {
      try {
        const [, stdout, stderr] = process.communicate_utf8_finish(result)

        if (!process.get_successful()) {
          console.error(
            `matugen failed (${process.get_exit_status()}): ${stderr || stdout || command.join(" ")}`,
          )
          return
        }

        restartAgs()
      } catch (error) {
        console.error(`Failed to run matugen: ${command.join(" ")}`, error)
      }
    })
  } catch (error) {
    console.error(`Failed to spawn matugen: ${command.join(" ")}`, error)
  }
}

function relativeLuminance(red: number, green: number, blue: number) {
  function toLinear(value: number) {
    const normalized = value / 255
    return normalized <= 0.04045
      ? normalized / 12.92
      : Math.pow((normalized + 0.055) / 1.055, 2.4)
  }

  return 0.2126 * toLinear(red) + 0.7152 * toLinear(green) + 0.0722 * toLinear(blue)
}

function pickMatugenMode(path: string): "light" | "dark" {
  try {
    const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 64, 64, true)
    const pixels = pixbuf.get_pixels()
    const width = pixbuf.get_width()
    const height = pixbuf.get_height()
    const rowstride = pixbuf.get_rowstride()
    const channels = pixbuf.get_n_channels()
    let luminance = 0
    let samples = 0

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const offset = y * rowstride + x * channels

        if (channels >= 4 && pixels[offset + 3] < 16) {
          continue
        }

        luminance += relativeLuminance(
          pixels[offset],
          pixels[offset + 1],
          pixels[offset + 2],
        )
        samples++
      }
    }

    return samples > 0 && luminance / samples >= 0.5 ? "light" : "dark"
  } catch (error) {
    console.error("Failed to detect wallpaper brightness for matugen", error)
    return "dark"
  }
}

function moveSelection(delta: number) {
  const count = backgrounds().length

  if (count === 0) {
    setSelectedIndex(-1)
    return
  }

  setSelectedIndex((index) => {
    const next = Math.max(0, Math.min(count - 1, index + delta))
    scrollSelectionIntoView(next)
    return next
  })
}

function scrollSelectionIntoView(index: number) {
  if (!wallpaperScroller || index < 0) {
    return
  }

  GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
    const adjustment = wallpaperScroller?.get_hadjustment()

    if (!adjustment) {
      return GLib.SOURCE_REMOVE
    }

    const itemWidth = 230
    const padding = 16
    const left = index * itemWidth
    const right = left + itemWidth
    const viewportLeft = adjustment.get_value()
    const viewportRight = viewportLeft + adjustment.get_page_size()
    let next = viewportLeft

    if (left < viewportLeft + padding) {
      next = left - padding
    } else if (right > viewportRight - padding) {
      next = right - adjustment.get_page_size() + padding
    }

    const max = adjustment.get_upper() - adjustment.get_page_size()
    adjustment.set_value(Math.max(adjustment.get_lower(), Math.min(max, next)))

    return GLib.SOURCE_REMOVE
  })
}

function scrollHorizontal(scrolledWindow: Gtk.ScrolledWindow, dx: number, dy: number) {
  const adjustment = scrolledWindow.get_hadjustment()

  if (!adjustment) {
    return false
  }

  const delta = dx || dy

  if (delta === 0) {
    return false
  }

  const amount = Math.abs(delta) < 10 ? delta * 90 : delta
  const max = adjustment.get_upper() - adjustment.get_page_size()
  const next = Math.max(adjustment.get_lower(), Math.min(max, adjustment.get_value() + amount))

  adjustment.set_value(next)
  return true
}

function handleKey(keyval: number) {
  switch (keyval) {
    case Gdk.KEY_Left:
      moveSelection(-1)
      return true
    case Gdk.KEY_Right:
      moveSelection(1)
      return true
    case Gdk.KEY_Return:
    case Gdk.KEY_KP_Enter:
      applyBackground(selectedBackground())
      return true
    case Gdk.KEY_Escape:
      closePicker()
      return true
    default:
      return false
  }
}

function BackgroundCard({
  entry,
  index,
}: {
  entry: BackgroundEntry
  index: number
}) {
  const isSelected = selectedIndex((value) => value === index)
  const isCurrent = currentBackgroundPath((path) => path === entry.path)

  return (
    <button
      class={isSelected((selected) =>
        selected ? "wallpaperCard wallpaperCardSelected" : "wallpaperCard",
      )}
      onClicked={() => {
        setSelectedIndex(index)
        applyBackground(entry)
      }}
      $={(button) => button.set_cursor_from_name("pointer")}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={6}
      >
        <Gtk.Picture
          class="wallpaperPreview"
          file={Gio.File.new_for_path(entry.path)}
          contentFit={Gtk.ContentFit.COVER}
          canShrink
        />

        <label
          class={isCurrent((current) =>
            current ? "wallpaperName wallpaperNameCurrent" : "wallpaperName",
          )}
          label={entry.name}
          ellipsize={Pango.EllipsizeMode.END}
          maxWidthChars={24}
          halign={Gtk.Align.CENTER}
          xalign={0.5}
        />
      </box>
    </button>
  )
}

function PickerPanel() {
  return (
    <box
      class="wallpaperPickerPanel"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={10}
      hexpand
    >
      <scrolledwindow
        class="wallpaperPickerScroller"
        hscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
        vscrollbarPolicy={Gtk.PolicyType.NEVER}
        hexpand
        $={(scrolledWindow) => {
          wallpaperScroller = scrolledWindow

          const scroll = Gtk.EventControllerScroll.new(Gtk.EventControllerScrollFlags.BOTH_AXES)
          scroll.connect("scroll", (_controller, dx, dy) => scrollHorizontal(scrolledWindow, dx, dy))
          scrolledWindow.add_controller(scroll)
        }}
      >
        <box
          class="wallpaperPickerRow"
          orientation={Gtk.Orientation.HORIZONTAL}
          spacing={12}
        >
          <For each={indexedBackgrounds}>
            {(entry) => (
              <BackgroundCard
                entry={entry}
                index={entry.index}
              />
            )}
          </For>
        </box>
      </scrolledwindow>

      <label
        class="wallpaperPickerEmpty"
        label="No backgrounds found"
        visible={backgrounds((items) => items.length === 0)}
      />
    </box>
  )
}

export default function WallpaperPicker(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const geometry = gdkmonitor.get_geometry()

  return (
    <window
      name="wallpaperpicker"
      class="WallpaperPicker"
      visible={false}
      decorated={false}
      resizable={false}
      canFocus
      $={(window) => {
        window.namespace = "ags-wallpaperpicker"
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
            refreshBackgrounds()
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
              window.grab_focus()
              return GLib.SOURCE_REMOVE
            })
          }
        })
      }}
    >
      <centerbox
        class="wallpaperPickerOverlay"
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={geometry.width}
        heightRequest={geometry.height}
        hexpand
        vexpand
        halign={Gtk.Align.FILL}
        valign={Gtk.Align.FILL}
      >
        <box
          $type="center"
          marginStart={50}
          marginEnd={50}
          hexpand
          halign={Gtk.Align.FILL}
        >
          <PickerPanel />
        </box>
      </centerbox>
    </window>
  )
}
