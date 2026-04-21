import app from "ags/gtk4/app"
import style from "./style.scss"
import Topbar from "./widget/Topbar"
import Background from "./widget/Background"
import Notifications from "./widget/Notification/Notifications"
import AppMenu from "./widget/AppMenu"
import { lock } from "./widget/LockScreen"

app.start({
  css: style,

  //LockScreen
  requestHandler(argv, res) {
    if (argv.includes("lock")) {
      res(lock() ? "ok" : "failed")
      return
    }

    res(`unknown request: ${argv.join(" ")}`)
  },
  
  main() {
    const monitors = app.get_monitors()

    monitors.map(Background)
    monitors.map(Topbar)
    monitors.map(AppMenu)

    const primaryMonitor = monitors[0]
    if (primaryMonitor) {
      Notifications(primaryMonitor)
    }
  },
})
