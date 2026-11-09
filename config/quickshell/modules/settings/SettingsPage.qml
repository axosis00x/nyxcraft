import QtQuick
import "../../components/material"
import "../../theme" as Palette

Flickable {
    id: root

    required property var panel
    property var sections: []

    contentWidth: width

    contentHeight: column.implicitHeight + 80
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            var delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y * 1.35 : event.angleDelta.y / 120 * 56;
            root.contentY = Math.max(0, Math.min(root.contentY - delta, root.contentHeight - root.height));
            event.accepted = true;
        }
    }

    Column {
        id: column
        width: Math.min(root.width, 760)
        x: (root.width - width) / 2
        spacing: Palette.Theme.spacingExtraLarge

        Repeater {
            model: root.sections

            delegate: Column {
                id: section

                required property var modelData
                readonly property bool tiles: modelData.layout === "tiles"
                readonly property bool gallery: ["themes", "wallpapers", "usage", "displays"].indexOf(modelData.layout) !== -1

                width: column.width
                spacing: Palette.Theme.spacingSmall

                Text {
                    visible: text !== ""
                    leftPadding: 4
                    text: section.modelData.title || ""
                    color: Palette.Theme.textMuted
                    font.family: Palette.Theme.fontSans
                    font.pixelSize: Palette.Theme.fontSizeXs
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    font.capitalization: Font.AllUppercase
                }

                Rectangle {
                    visible: !section.tiles && !section.gallery
                    width: section.width
                    height: rows.implicitHeight
                    radius: Palette.Theme.radiusMedium
                    color: Palette.Theme.surfaceContainer

                    Column {
                        id: rows
                        width: parent.width

                        Repeater {
                            model: section.tiles || section.gallery ? [] : section.modelData.rows

                            delegate: SettingsEntry {
                                required property var modelData
                                required property int index

                                width: rows.width
                                panel: root.panel
                                spec: modelData
                                isFirst: index === 0
                                isLast: index === section.modelData.rows.length - 1
                            }
                        }
                    }
                }

                Flow {
                    id: tileFlow
                    visible: section.tiles
                    width: section.width
                    spacing: Palette.Theme.spacingSmall

                    readonly property int columns: 3

                    Repeater {
                        model: section.tiles ? section.modelData.rows : []

                        delegate: SettingsTileEntry {
                            required property var modelData

                            width: (tileFlow.width - tileFlow.spacing * (tileFlow.columns - 1)) / tileFlow.columns
                            panel: root.panel
                            spec: modelData
                        }
                    }
                }

                Loader {
                    active: section.gallery && root.panel.shown
                    visible: active
                    width: section.width
                    height: item ? item.implicitHeight : 0
                    sourceComponent: ({
                            themes: themeGrid,
                            wallpapers: wallpaperGrid,
                            usage: usageCards,
                            displays: displayCards
                        })[section.modelData.layout]
                }
            }
        }
    }

    Component {
        id: themeGrid
        SettingsThemeGrid {
            service: root.panel.themeService
        }
    }

    Component {
        id: displayCards
        SettingsDisplays {
            service: root.panel.displayService
        }
    }

    Component {
        id: usageCards
        SettingsUsageCards {
            panel: root.panel
        }
    }

    Component {
        id: wallpaperGrid
        SettingsWallpaperGrid {
            service: root.panel.themeService
        }
    }
}
