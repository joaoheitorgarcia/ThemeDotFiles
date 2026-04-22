import AstalTray from "gi://AstalTray"
import Gtk from "gi://Gtk?version=4.0"
import { createBinding, createState, For } from "gnim"

type TrayItem = any

const tray = AstalTray.Tray.get_default()

function trayItems() {
  return Array.from(tray.items ?? []) as TrayItem[]
}

function trayMenuModel(item: TrayItem) {
  return item.menu_model ?? item.menuModel ?? item.get_menu_model?.() ?? null
}

function trayActionGroup(item: TrayItem) {
  return item.action_group ?? item.actionGroup ?? item.get_action_group?.() ?? null
}

function prepareTrayMenu(item: TrayItem, button: Gtk.MenuButton) {
  item.about_to_show?.()

  const menuModel = trayMenuModel(item)
  const actionGroup = trayActionGroup(item)
  button.insert_action_group("dbusmenu", actionGroup)
  button.menuModel = menuModel
}

function showTrayMenu(item: TrayItem, button: Gtk.MenuButton) {
  prepareTrayMenu(item, button)

  if (!trayMenuModel(item) || !trayActionGroup(item)) {
    item.secondary_activate?.(0, 0)
    return
  }

  button.popup()
}

function suppressTrayHighlight(button: Gtk.MenuButton) {
  button.remove_css_class("trayPressed")
  button.add_css_class("trayActionTaken")
}

function TrayIcon({ item }: { item: TrayItem }) {
  const gicon = createBinding(item, "gicon")
  const tooltip = createBinding(item, "tooltip-text").as((value) =>
    String(value || item.title || ""),
  )

  return (
    <image
      class="appTrayIcon"
      gicon={gicon}
      pixelSize={24}
      tooltipText={tooltip}
      useFallback
    />
  )
}

function TrayButton({ item }: { item: TrayItem }) {
  return (
    <menubutton
      class="appTrayItem"
      alwaysShowArrow={false}
      direction={Gtk.ArrowType.NONE}
      hasFrame={false}
      menuModel={createBinding(item, "menu-model")}
      tooltipText={createBinding(item, "tooltip-text").as((value) =>
        String(value || item.title || ""),
      )}
      $={(widget) => {
        widget.set_cursor_from_name("pointer")
        widget.insert_action_group("dbusmenu", trayActionGroup(item))
        item.connect?.("notify::action-group", () => {
          widget.insert_action_group("dbusmenu", trayActionGroup(item))
        })
        item.connect?.("notify::menu-model", () => {
          widget.menuModel = trayMenuModel(item)
        })
        widget.connect("notify::active", () => {
          if (!widget.active) {
            suppressTrayHighlight(widget)
          }
        })

        let pressedButton = 0

        const click = Gtk.GestureClick.new()
        click.set_button(0)
        click.connect("pressed", () => {
          pressedButton = click.get_current_button()
          prepareTrayMenu(item, widget)
          widget.remove_css_class("trayActionTaken")
          widget.add_css_class("trayPressed")
        })
        click.connect("released", () => {
          widget.remove_css_class("trayPressed")

          if (pressedButton === 3) {
            showTrayMenu(item, widget)
          }

          pressedButton = 0
        })
        widget.add_controller(click)

        const motion = Gtk.EventControllerMotion.new()
        motion.connect("leave", () => {
          widget.remove_css_class("trayActionTaken")
        })
        widget.add_controller(motion)
      }}
    >
      <TrayIcon item={item} />
    </menubutton>
  )
}

export default function AppTray() {
  const [items, setItems] = createState(trayItems())

  function refreshItems() {
    setItems(trayItems())
  }

  tray.connect("item-added", refreshItems)
  tray.connect("item-removed", refreshItems)

  return (
    <box
      class="appTray"
      visible={items((items) => items.length > 0)}
    >
      <For each={items}>
        {(item: TrayItem) => <TrayButton item={item} />}
      </For>
    </box>
  )
}
