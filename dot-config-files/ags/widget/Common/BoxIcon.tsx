import Gio from "gi://Gio"
import Rsvg from "gi://Rsvg?version=2.0"
import { Gtk } from "ags/gtk4"

type BoxIconVariant = "basic" | "brands" | "filled"

type BoxIconProps = {
    name: string
    variant?: BoxIconVariant
    size?: number
    color?: string
    class?: string
    css?: string
    $?: (area: Gtk.DrawingArea) => void
}

const svgCache = new Map<string, string>()
const handleCache = new Map<string, Rsvg.Handle>()

function getIconName(name: string) {
    return name.startsWith("bx-") ? name : `bx-${name}`
}

function getIconPath(name: string, variant: BoxIconVariant) {
    return `${SRC}/node_modules/@boxicons/core/svg/${variant}/${getIconName(name)}.svg`
}

function getSvgSource(path: string) {
    const cached = svgCache.get(path)

    if (cached) {
        return cached
    }

    const file = Gio.File.new_for_path(path)
    const [, bytes] = file.load_contents(null)
    const svg = new TextDecoder().decode(bytes)

    svgCache.set(path, svg)

    return svg
}

function getTintedSvg(path: string, color: string) {
    const svg = getSvgSource(path)

    if (svg.includes("<svg")) {
        return svg.replace("<svg", `<svg fill="${color}" color="${color}"`)
    }

    return svg
}

function getHandle(path: string, color: string) {
    const cacheKey = `${path}:${color}`
    const cached = handleCache.get(cacheKey)

    if (cached) {
        return cached
    }

    try {
        const handle = Rsvg.Handle.new_from_data(getTintedSvg(path, color))

        handleCache.set(cacheKey, handle)

        return handle
    } catch (error) {
        console.error(`Failed to load Boxicon from ${path}`, error)
        return null
    }
}

export default function BoxIcon({
    name,
    variant = "basic",
    size = 18,
    color,
    $,
    ...props
}: BoxIconProps) {
    const path = getIconPath(name, variant)

    return (
        <drawingarea
            {...props}
            contentWidth={size}
            contentHeight={size}
            widthRequest={size}
            heightRequest={size}
            $={(area) => {
                area.set_draw_func((_area, cr, width, height) => {
                    const resolvedColor = color ?? area.get_color().to_string()
                    const handle = getHandle(path, resolvedColor)

                    if (!handle) {
                        return
                    }

                    handle.render_document(
                        cr,
                        new Rsvg.Rectangle({
                            x: 0,
                            y: 0,
                            width,
                            height,
                        }),
                    )
                })

                $?.(area)
            }}
        />
    )
}
