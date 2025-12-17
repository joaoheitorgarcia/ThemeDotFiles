pragma Singleton
import QtQuick

QtObject {
    id: matugenTheme

    // ──────────────
    // Primary
    // ──────────────
    readonly property color primary:                 "#a4c9fe"
    readonly property color primaryText:             "#00315c"
    readonly property color primaryContainer:        "#1f4876"
    readonly property color primaryContainerText:    "#d3e3ff"

    // ──────────────
    // Secondary
    // ──────────────
    readonly property color secondary:               "#bcc7db"
    readonly property color secondaryText:           "#263141"
    readonly property color secondaryContainer:      "#3c4758"
    readonly property color secondaryContainerText:  "#d8e3f8"

    // ──────────────
    // Tertiary
    // ──────────────
    readonly property color tertiary:                "#d9bde3"
    readonly property color tertiaryText:            "#3c2946"
    readonly property color tertiaryContainer:       "#543f5e"
    readonly property color tertiaryContainerText:   "#f5d9ff"

    // ──────────────
    // Error
    // ──────────────
    readonly property color errorColor:              "#ffb4ab"
    readonly property color errorText:               "#690005"
    readonly property color errorContainer:          "#93000a"
    readonly property color errorContainerText:      "#ffdad6"

    // ──────────────
    // Background
    // ──────────────
    readonly property color background:              "#111318"
    readonly property color backgroundText:          "#e1e2e9"

    // ──────────────
    // Surface
    // ──────────────
    readonly property color surface:                 "#111318"
    readonly property color surfaceText:             "#e1e2e9"

    readonly property color surfaceVariant:          "#43474e"
    readonly property color surfaceVariantText:      "#c3c6cf"

    readonly property color surfaceDim:              "#111318"
    readonly property color surfaceBright:           "#37393e"

    // Container ladder (great for hover/pressed/focus depth)
    readonly property color surfaceContainerLowest:  "#0c0e13"
    readonly property color surfaceContainerLow:     "#191c20"
    readonly property color surfaceContainer:        "#1d2024"
    readonly property color surfaceContainerHigh:    "#272a2f"
    readonly property color surfaceContainerHighest: "#32353a"

    // Tint (often used for overlays/elevation in M3)
    readonly property color surfaceTint:             "#a4c9fe"

    // ──────────────
    // Outline
    // ──────────────
    readonly property color outline:                 "#8d9199"
    readonly property color outlineVariant:          "#43474e"

    // ──────────────
    // Shadow / Scrim
    // ──────────────
    readonly property color shadow:                  "#000000"
    readonly property color scrim:                   "#000000"

    // ──────────────
    // Inverse
    // ──────────────
    readonly property color inverseSurface:          "#e1e2e9"
    readonly property color inverseSurfaceText:      "#2e3035"
    readonly property color inversePrimary:          "#3a608f"

    // ──────────────
    // Fixed colors (useful for “brand stays stable” areas)
    // ──────────────
    readonly property color primaryFixed:            "#d3e3ff"
    readonly property color primaryFixedDim:         "#a4c9fe"
    readonly property color primaryFixedText:        "#001c39"
    readonly property color primaryFixedVariantText: "#1f4876"

    readonly property color secondaryFixed:            "#d8e3f8"
    readonly property color secondaryFixedDim:         "#bcc7db"
    readonly property color secondaryFixedText:        "#111c2b"
    readonly property color secondaryFixedVariantText: "#3c4758"

    readonly property color tertiaryFixed:            "#f5d9ff"
    readonly property color tertiaryFixedDim:         "#d9bde3"
    readonly property color tertiaryFixedText:        "#261430"
    readonly property color tertiaryFixedVariantText: "#543f5e"
}
