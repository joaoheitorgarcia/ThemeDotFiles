import Gio from "gi://Gio"
import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"

const backgroundFile = Gio.File.new_for_path(
  `${SRC}/assets/background-images/car-sunset.png`,
)

export default function Background(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor

  return (
    <window
      name="background"
      class="Background"
      $={(win) => {
        win.namespace = "ags-background"
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
