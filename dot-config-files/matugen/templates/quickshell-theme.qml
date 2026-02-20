pragma Singleton
import QtQuick

QtObject {
    id: matugenTheme

    readonly property string mode:                   "{{ mode }}"

    // ──────────────
    // Primary
    // ──────────────
    readonly property color primary:                 "{{ colors.primary.dark.hex }}"
    readonly property color primaryText:             "{{ colors.on_primary.dark.hex }}"
    readonly property color primaryContainer:        "{{ colors.primary_container.dark.hex }}"
    readonly property color primaryContainerText:    "{{ colors.on_primary_container.dark.hex }}"

    // ──────────────
    // Secondary
    // ──────────────
    readonly property color secondary:               "{{ colors.secondary.dark.hex }}"
    readonly property color secondaryText:           "{{ colors.on_secondary.dark.hex }}"
    readonly property color secondaryContainer:      "{{ colors.secondary_container.dark.hex }}"
    readonly property color secondaryContainerText:  "{{ colors.on_secondary_container.dark.hex }}"

    // ──────────────
    // Tertiary
    // ──────────────
    readonly property color tertiary:                "{{ colors.tertiary.dark.hex }}"
    readonly property color tertiaryText:            "{{ colors.on_tertiary.dark.hex }}"
    readonly property color tertiaryContainer:       "{{ colors.tertiary_container.dark.hex }}"
    readonly property color tertiaryContainerText:   "{{ colors.on_tertiary_container.dark.hex }}"

    // ──────────────
    // Error
    // ──────────────
    readonly property color errorColor:              "{{ colors.error.dark.hex }}"
    readonly property color errorText:               "{{ colors.on_error.dark.hex }}"
    readonly property color errorContainer:          "{{ colors.error_container.dark.hex }}"
    readonly property color errorContainerText:      "{{ colors.on_error_container.dark.hex }}"

    // ──────────────
    // Background
    // ──────────────
    readonly property color background:              "{{ colors.background.dark.hex }}"
    readonly property color backgroundText:          "{{ colors.on_background.dark.hex }}"

    // ──────────────
    // Surface
    // ──────────────
    readonly property color surface:                 "{{ colors.surface.dark.hex }}"
    readonly property color surfaceText:             "{{ colors.on_surface.dark.hex }}"

    readonly property color surfaceVariant:          "{{ colors.surface_variant.dark.hex }}"
    readonly property color surfaceVariantText:      "{{ colors.on_surface_variant.dark.hex }}"

    readonly property color surfaceDim:              "{{ colors.surface_dim.dark.hex }}"
    readonly property color surfaceBright:           "{{ colors.surface_bright.dark.hex }}"

    // Container ladder (great for hover/pressed/focus depth)
    readonly property color surfaceContainerLowest:  "{{ colors.surface_container_lowest.dark.hex }}"
    readonly property color surfaceContainerLow:     "{{ colors.surface_container_low.dark.hex }}"
    readonly property color surfaceContainer:        "{{ colors.surface_container.dark.hex }}"
    readonly property color surfaceContainerHigh:    "{{ colors.surface_container_high.dark.hex }}"
    readonly property color surfaceContainerHighest: "{{ colors.surface_container_highest.dark.hex }}"

    // Tint (often used for overlays/elevation in M3)
    readonly property color surfaceTint:             "{{ colors.surface_tint.dark.hex }}"

    // ──────────────
    // Outline
    // ──────────────
    readonly property color outline:                 "{{ colors.outline.dark.hex }}"
    readonly property color outlineVariant:          "{{ colors.outline_variant.dark.hex }}"

    // ──────────────
    // Shadow / Scrim
    // ──────────────
    readonly property color shadow:                  "{{ colors.shadow.dark.hex }}"
    readonly property color scrim:                   "{{ colors.scrim.dark.hex }}"

    // ──────────────
    // Inverse
    // ──────────────
    readonly property color inverseSurface:          "{{ colors.inverse_surface.dark.hex }}"
    readonly property color inverseSurfaceText:      "{{ colors.inverse_on_surface.dark.hex }}"
    readonly property color inversePrimary:          "{{ colors.inverse_primary.dark.hex }}"

    // ──────────────
    // Fixed colors (useful for “brand stays stable” areas)
    // ──────────────
    readonly property color primaryFixed:            "{{ colors.primary_fixed.dark.hex }}"
    readonly property color primaryFixedDim:         "{{ colors.primary_fixed_dim.dark.hex }}"
    readonly property color primaryFixedText:        "{{ colors.on_primary_fixed.dark.hex }}"
    readonly property color primaryFixedVariantText: "{{ colors.on_primary_fixed_variant.dark.hex }}"

    readonly property color secondaryFixed:            "{{ colors.secondary_fixed.dark.hex }}"
    readonly property color secondaryFixedDim:         "{{ colors.secondary_fixed_dim.dark.hex }}"
    readonly property color secondaryFixedText:        "{{ colors.on_secondary_fixed.dark.hex }}"
    readonly property color secondaryFixedVariantText: "{{ colors.on_secondary_fixed_variant.dark.hex }}"

    readonly property color tertiaryFixed:            "{{ colors.tertiary_fixed.dark.hex }}"
    readonly property color tertiaryFixedDim:         "{{ colors.tertiary_fixed_dim.dark.hex }}"
    readonly property color tertiaryFixedText:        "{{ colors.on_tertiary_fixed.dark.hex }}"
    readonly property color tertiaryFixedVariantText: "{{ colors.on_tertiary_fixed_variant.dark.hex }}"
}
