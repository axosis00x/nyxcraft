pragma Singleton

import QtQuick

QtObject {
    id: root

    property var bg: "#030305"
    property var surface: "#030305"
    property var surfaceContainerLow: "#101018"
    property var surfaceContainer: "#0a0a10"
    property var surfaceContainerHigh: "#181822"
    property var surfaceContainerHighest: "#22222e"
    property var surfaceTint: "#eef5f7"
    property var outlineVariant: "#233240"
    property var border: "#233240"
    property var accent: "#29c4d9"
    property var accentText: "#00161b"
    property var info: "#29c4d9"
    property var warning: "#d99a2b"
    property var success: "#2ecc76"
    property var errorColor: "#dd3f66"
    property var accentLight: "#07161a"
    property var primaryContainer: "#0a2d36"
    property var primaryText: "#a8dbe6"
    property var secondaryContainer: "#22102e"
    property var secondaryContainerHover: "#2c1640"

    property var secondaryText: "#c9a8dc"
    property var wsInactive: "#4a5a68"
    property var textPrimary: "#eef5f7"
    property var textTitle: "#eef5f7"
    property var textSecondary: "#9fb4c4"
    property var textMuted: "#6c8494"
    property var textDisabled: "#2c3a46"

    readonly property color osdBackground: "#050608"
    readonly property color osdTrack: "#292b30"
    readonly property color osdText: "#f5f5f2"
    readonly property color osdMuted: "#a8abb2"

    property var blue: "#83a598"
    property var green: "#b8bb26"
    property var yellow: "#fabd2f"
    property var purple: "#d3869b"
    property var aqua: "#8ec07c"
    property var orange: "#fe8019"

    readonly property real surfaceTintOpacity: 0.015
    readonly property string fontMono: "SF Mono "
    readonly property string fontSans: "Inter"
    readonly property string fontIcons: "Material Symbols Rounded "

    readonly property int iconWeight: Font.Medium

    property real roundness: 1.0
    property int controlCenterWidth: 480
    property real dockIconScale: 1.0
    property bool dockAutoHide: true
    property bool showGlyph: true
    property bool clockSeconds: false
    property bool clock24h: false
    property real clockScale: 1.0
    property real weatherScale: 1.0
    property real cavaScale: 1.0

    readonly property int radiusXs: Math.round(6 * roundness)
    readonly property int radiusSmall: Math.round(13 * roundness)
    readonly property int radiusMedium: Math.round(13 * roundness)
    readonly property int radiusLarge: Math.round(20 * roundness)
    readonly property int radiusExtraLarge: Math.round(28 * roundness)

    readonly property int spacingXs: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingExtraLarge: 24

    readonly property int fontSizeXs: 11
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeBody: 13
    readonly property int fontSizeTitle: 16
    readonly property int fontSizeHeadline: 20
    readonly property int fontSizeDisplay: 28
    readonly property int iconSizeSmall: 16
    readonly property int iconSize: 18
    readonly property int iconSizeLarge: 22

    readonly property int iconButtonSize: 30

    readonly property int barThickness: 40
    readonly property int barHeight: 34
    readonly property int listPanelWidth: 440
    readonly property int screenFrameBorder: 4
    readonly property int screenFrameRadius: 10

    readonly property int motionFast: 180
    readonly property int motionDefault: 320
    readonly property int motionSlow: 480
    readonly property int effectFast: 110
    readonly property int effectDefault: 200
    readonly property real springOvershoot: 0.6
    readonly property real springBouncy: 1.0

    readonly property real stateHover: 0.08
    readonly property real statePressed: 0.12
    readonly property real stateSelected: 0.16

    readonly property color accentTonal: Qt.alpha(accent, stateSelected)

    readonly property color outlineColor: outlineVariant
    readonly property color outlineSoft: Qt.rgba(outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a * 0.35)
    readonly property color surfaceSolid: Qt.alpha(bg, 1)

    readonly property color widgetSurface: Qt.alpha(Qt.tint(surfaceSolid, Qt.alpha(textPrimary, 0.05)), 0.85)

    readonly property color widgetChip: Qt.alpha(textPrimary, 0.08)

    function hueFor(name) {
        var hues = [blue, green, yellow, purple, aqua, orange];
        var h = 0;
        var s = String(name || "");
        for (var i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) | 0;
        return hues[Math.abs(h) % hues.length];
    }

    function apply(values) {
        var paletteKeys = ["bg", "surface", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceTint", "outlineVariant", "border", "accent", "accentText", "info", "warning", "success", "errorColor", "accentLight", "primaryContainer", "primaryText", "secondaryContainer", "secondaryContainerHover", "secondaryText", "wsInactive", "textPrimary", "textTitle", "textSecondary", "textMuted", "textDisabled", "blue", "green", "yellow", "purple", "aqua", "orange"];
        for (var key in values) {
            if (paletteKeys.indexOf(key) !== -1)
                root[key] = values[key];
        }
    }
}
