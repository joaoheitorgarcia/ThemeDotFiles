import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { Astal, Gdk } from "ags/gtk4"
import DateTime from "./Topbar/DateTime"
import LockToggle from "./Topbar/LockToggle"
import NotificationList from "./Topbar/NotificationList"
import Workspaces from "./Topbar/Workspaces"
import PowerActions from "./Topbar/PowerActions"
import BatteryInfo from "./Topbar/BatteryInfo"
import Bluetooth from "./Topbar/Bluetooth"

export default function Topbar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="topbar"
      class="Topbar"
      $={(win) => {
        win.namespace = "ags-topbar"
        win.gdkmonitor = gdkmonitor
        win.exclusivity = Astal.Exclusivity.EXCLUSIVE
        win.anchor = TOP | LEFT | RIGHT
        win.layer = Astal.Layer.TOP
        win.application = app
        win.visible = true
      }}
    >
      <centerbox
        cssName="centerbox"
        hexpand
        halign={Gtk.Align.FILL}
      >
        {/* START */}
        <box
          $type="start"
          class="topbarStart"
        >
          <Workspaces/>
        </box>
    
        {/* CENTER */}
        <box $type="center">
        </box>

        {/* END */}
        <box
          $type="end"
          class="topbarEnd"
        >
          <LockToggle />
          <NotificationList />
          <DateTime />
          <Bluetooth />
          <BatteryInfo/>
          <PowerActions /> 
        </box>
      </centerbox>
    </window>
  )
}
