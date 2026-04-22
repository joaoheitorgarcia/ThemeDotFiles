import Gio from "gi://Gio"
import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { monitorId } from "./Common/Monitor"

const backgroundFile = Gio.File.new_for_path(
  `${SRC}/assets/background-images/car-sunset.png`,
)

export default function Background(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const id = monitorId(gdkmonitor)

  return (
    <window
      name={`background-${id}`}
      class="Background"
      $={(win) => {
        win.namespace = `ags-background-${id}`
        win.gdkmonitor = gdkmonitor
        win.exclusivity = Astal.Exclusivity.IGNORE
        win.anchor = TOP | LEFT | RIGHT | BOTTOM
        win.layer = Astal.Layer.BACKGROUND
        win.application = app
        win.visible = true
      }}
    >
      <Gtk.Picture
        class="BackgroundImage"
        file={backgroundFile}
        hexpand
        vexpand
        canShrink
        contentFit={Gtk.ContentFit.COVER}
      />
    </window>
  )
}
