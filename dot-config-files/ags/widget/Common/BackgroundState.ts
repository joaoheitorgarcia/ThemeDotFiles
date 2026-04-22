import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"
import { createState } from "gnim"

export type BackgroundEntry = {
  name: string
  path: string
}

const backgroundDir = `${SRC}/assets/backgrounds`
const selectedBackgroundPath = `${backgroundDir}/.current-background`
const imageExtensions = [".png", ".jpg", ".jpeg", ".webp"]

function decodeContents(contents: unknown) {
  if (typeof contents === "string") {
    return contents
  }

  return String.fromCharCode(...(contents as Uint8Array))
}

function isBackgroundFile(name: string) {
  const lower = name.toLowerCase()
  return imageExtensions.some((extension) => lower.endsWith(extension))
}

function readSelectedBackgroundName() {
  try {
    const [, contents] = Gio.File.new_for_path(selectedBackgroundPath).load_contents(null)
    return decodeContents(contents).trim()
  } catch {
    return ""
  }
}

function writeSelectedBackgroundName(name: string) {
  try {
    GLib.mkdir_with_parents(backgroundDir, 0o755)
    GLib.file_set_contents(selectedBackgroundPath, `${name}\n`)
  } catch (error) {
    console.error("Failed to persist selected background", error)
  }
}

export function listBackgrounds() {
  try {
    GLib.mkdir_with_parents(backgroundDir, 0o755)

    const directory = Gio.File.new_for_path(backgroundDir)
    const enumerator = directory.enumerate_children(
      "standard::name,standard::type",
      Gio.FileQueryInfoFlags.NONE,
      null,
    )
    const entries: BackgroundEntry[] = []

    for (
      let info = enumerator.next_file(null);
      info;
      info = enumerator.next_file(null)
    ) {
      const name = info.get_name()

      if (info.get_file_type() === Gio.FileType.REGULAR && isBackgroundFile(name)) {
        entries.push({
          name,
          path: GLib.build_filenamev([backgroundDir, name]),
        })
      }
    }

    enumerator.close(null)
    return entries.sort((a, b) => a.name.localeCompare(b.name))
  } catch (error) {
    console.error("Failed to list backgrounds", error)
    return []
  }
}

function initialBackgroundPath() {
  const entries = listBackgrounds()
  const selectedName = readSelectedBackgroundName()
  const selected = entries.find((entry) => entry.name === selectedName)

  return selected?.path ?? entries.find((entry) => entry.name === "car-sunset.png")?.path ?? entries[0]?.path ?? ""
}

export const [currentBackgroundPath, setCurrentBackgroundPath] = createState(initialBackgroundPath())

export function selectBackground(entry: BackgroundEntry) {
  writeSelectedBackgroundName(entry.name)
  setCurrentBackgroundPath(entry.path)
}
