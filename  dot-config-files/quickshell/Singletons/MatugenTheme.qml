pragma Singleton
import QtQuick

QtObject {
    id: matugenTheme

    // ──────────────
    // Primary
    // ──────────────
    readonly property color primary:                 "#3a608f"
    readonly property color primaryText:             "#ffffff"
    readonly property color primaryContainer:        "#d3e3ff"
    readonly property color primaryContainerText:    "#001c39"

    // ──────────────
    // Secondary
    // ──────────────
    readonly property color secondary:               "#545f70"
    readonly property color secondaryText:           "#ffffff"
    readonly property color secondaryContainer:      "#d8e3f8"
    readonly property color secondaryContainerText:  "#111c2b"

    // ──────────────
    // Tertiary
    // ──────────────
    readonly property color tertiary:                "#6d5677"
    readonly property color tertiaryText:            "#ffffff"
    readonly property color tertiaryContainer:       "#f5d9ff"
    readonly property color tertiaryContainerText:   "#261430"

    // ──────────────
    // Error
    // ──────────────
    readonly property color errorColor:              "#ba1a1a"
    readonly property color errorText:               "#ffffff"
    readonly property color errorContainer:          "#ffdad6"
    readonly property color errorContainerText:      "#410002"

    // ──────────────
    // Background
    // ──────────────
    readonly property color background:              "#f8f9ff"
    readonly property color backgroundText:          "#191c20"

    // ──────────────
    // Surface
    // ──────────────
    readonly property color surface:                 "#f8f9ff"
    readonly property color surfaceText:             "#191c20"

    readonly property color surfaceVariant:          "#dfe2eb"
    readonly property color surfaceVariantText:      "#43474e"

    readonly property color surfaceDim:              "#d9dae0"
    readonly property color surfaceBright:           "#f8f9ff"

    // Container ladder (great for hover/pressed/focus depth)
    readonly property color surfaceContainerLowest:  "#ffffff"
    readonly property color surfaceContainerLow:     "#f2f3fa"
    readonly property color surfaceContainer:        "#ededf4"
    readonly property color surfaceContainerHigh:    "#e7e8ee"
    readonly property color surfaceContainerHighest: "#e1e2e9"

    // Tint (often used for overlays/elevation in M3)
    readonly property color surfaceTint:             "#3a608f"

    // ──────────────
    // Outline
    // ──────────────
    readonly property color outline:                 "#73777f"
    readonly property color outlineVariant:          "#c3c6cf"

    // ──────────────
    // Shadow / Scrim
    // ──────────────
    readonly property color shadow:                  "#000000"
    readonly property color scrim:                   "#000000"

    // ──────────────
    // Inverse
    // ──────────────
    readonly property color inverseSurface:          "#2e3035"
    readonly property color inverseSurfaceText:      "#eff0f7"
    readonly property color inversePrimary:          "#a4c9fe"

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
