import { Gdk } from "ags/gtk4"

const monitorObjectIds = new WeakMap<Gdk.Monitor, string>()
let nextMonitorObjectId = 1

export function monitorId(gdkmonitor: Gdk.Monitor) {
  const connector = String(gdkmonitor.get_connector?.() ?? gdkmonitor.connector ?? "").trim()

  if (connector) {
    return connector.replace(/[^A-Za-z0-9_.-]/g, "-")
  }

  const id = monitorObjectIds.get(gdkmonitor) ?? `monitor-${nextMonitorObjectId++}`
  monitorObjectIds.set(gdkmonitor, id)

  return id
}
