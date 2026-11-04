import QtQuick
import Quickshell.Io
import "../../theme" as Palette

// Compact bar version of Bongo Cat, using the classic bongocat vector font
// (the same artwork as the dms-plugins widget) instead of pixel sprites.
// libinput reports key events from every keyboard and the cat switches
// glyphs for each press.
Item {
    id: root

    property bool enabled: true
    property int pawState: 0
    property bool leftWasLast: false

    implicitWidth: cat.implicitWidth
    implicitHeight: cat.implicitHeight

    FontLoader {
        id: bongoFont
        source: Qt.resolvedUrl("../../assets/bongo-cat/bongocat-Regular.otf")
        onStatusChanged: {
            if (status === FontLoader.Error)
                console.warn("[BongoCat] Failed to load font");
        }
    }

    function tap(keyName) {
        if (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER") {
            pawState = 3;
        } else if (pawState === 0) {
            leftWasLast = !leftWasLast;
            pawState = leftWasLast ? 1 : 2;
        } else {
            pawState = 3;
        }
        releaseTimer.restart();
    }

    Process {
        id: inputEvents
        command: ["libinput", "debug-events", "--show-keycodes"]
        running: root.enabled

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.includes("KEYBOARD_KEY") || (!line.includes("pressed") && !line.includes("repeat")))
                    return;
                const match = line.match(/(KEY_[A-Z0-9_]+)/);
                root.tap(match ? match[1] : "");
            }
        }
    }

    Timer {
        id: releaseTimer
        interval: 100
        onTriggered: root.pawState = 0
    }

    Text {
        id: cat
        anchors.centerIn: parent
        font.family: bongoFont.name
        font.pixelSize: 24
        color: Palette.Theme.textPrimary

        // The font composes each pose out of glyph pairs.
        text: {
            switch (root.pawState) {
            case 1: return "dc";
            case 2: return "ba";
            case 3: return "da";
            default: return "bc";
            }
        }
    }
}
