import AstalTray from "gi://AstalTray"
import Gtk from "gi://Gtk?version=4.0"
import { createBinding, createState, For } from "gnim"

type TrayItem = any

const tray = AstalTray.Tray.get_default()

function trayItems() {
  return Array.from(tray.items ?? []) as TrayItem[]
}

function showTrayMenu(item: TrayItem, button: Gtk.Button) {
  const menuModel = item.menu_model ?? item.menuModel ?? item.get_menu_model?.()
  const actionGroup = item.action_group ?? item.actionGroup ?? item.get_action_group?.()

  if (!menuModel || !actionGroup) {
    item.secondary_activate?.(0, 0)
    return
  }

  item.about_to_show?.()
  button.insert_action_group("dbusmenu", actionGroup)

  const popover = Gtk.PopoverMenu.new_from_model(menuModel)
  popover.hasArrow = false
  popover.set_parent(button)
  popover.connect("closed", () => popover.unparent())
  popover.popup()
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
  let button: Gtk.Button | undefined
  let releasedButton = 0

  function isMenuItem() {
    return Boolean(item.is_menu ?? item.isMenu ?? item.get_is_menu?.())
  }

  function activate(button: Gtk.Button) {
    if (isMenuItem()) {
      showTrayMenu(item, button)
      return
    }

    item.activate?.(0, 0)
  }

  return (
    <button
      class="appTrayItem"
      tooltipText={createBinding(item, "tooltip-text").as((value) =>
        String(value || item.title || ""),
      )}
      $={(widget) => {
        button = widget
        widget.set_cursor_from_name("pointer")

        let pressedButton = 0

        const click = Gtk.GestureClick.new()
        click.set_button(0)
        click.connect("pressed", () => {
          pressedButton = click.get_current_button()
          widget.add_css_class("trayPressed")
        })
        click.connect("released", () => {
          widget.remove_css_class("trayPressed")
          releasedButton = pressedButton

          if (pressedButton === 3) {
            showTrayMenu(item, widget)
          }

          pressedButton = 0
        })
        widget.add_controller(click)
      }}
      onClicked={() => {
        if (button && releasedButton !== 3) {
          activate(button)
        }

        releasedButton = 0
      }}
    >
      <TrayIcon item={item} />
    </button>
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
