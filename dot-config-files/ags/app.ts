import app from "ags/gtk4/app"
import style from "./style.scss"
import Topbar from "./widget/Topbar"
import Background from "./widget/Background"
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
    app.get_monitors().map(Background)
    app.get_monitors().map(Topbar)
  },
})
