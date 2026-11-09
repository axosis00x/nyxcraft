import Quickshell
import QtQuick
import "../../theme" as Palette

Text {
    id: root

    text: Qt.formatDateTime(clock.date, "hh:mm")
    horizontalAlignment: Text.AlignHCenter

    color: Palette.Theme.textPrimary
    font.family: Palette.Theme.fontMono
    font.pixelSize: Palette.Theme.fontSizeSmall
    font.weight: Font.DemiBold

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
