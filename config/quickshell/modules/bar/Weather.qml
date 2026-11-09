import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme" as Palette

Item {
    id: root
    property bool vertical: false
    property string tempC: ""
    property string conditionText: ""
    property int weatherCode: 0
    property bool isStale: false
    readonly property bool available: tempC !== ""
    readonly property string iconFontFamily: Palette.Theme.fontIcons || "Material Symbols Outlined"

    readonly property string iconGlyph: {
        var c = root.weatherCode;
        if (c === 113)
            return "wb_sunny";
        if (c === 116)
            return "partly_cloudy_day";
        if ([119, 122, 143, 248, 260].includes(c))
            return "cloud";
        if ([176, 179, 182, 185, 200, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359, 386, 389].includes(c))
            return "rainy";
        if ([227, 230, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377, 392, 395].includes(c))
            return "weather_snowy";
        return "cloud";
    }

    visible: available
    implicitWidth: root.vertical ? Math.max(24, row.implicitWidth) : row.implicitWidth
    implicitHeight: root.vertical ? row.implicitHeight : 30

    function refresh() {
        weatherProcess.running = true;
    }

    FileView {
        id: cacheFile
        path: Quickshell.cachePath("weather-cache.json")
        watchChanges: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: cache
            property string tempC: ""
            property string conditionText: ""
            property int weatherCode: 0
            onTempCChanged: {
                if (root.tempC === "" && cache.tempC !== "") {
                    root.tempC = cache.tempC;
                    root.conditionText = cache.conditionText;
                    root.weatherCode = cache.weatherCode;
                    root.isStale = true;
                }
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: reconnectDebounce
        interval: 2000
        onTriggered: root.refresh()
    }

    Process {
        id: networkMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("connected") || data.includes("Connectivity"))
                    reconnectDebounce.restart();
            }
        }
    }

    Process {
        id: weatherProcess
        command: ["curl", "-s", "--max-time", "8", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var current = JSON.parse(text).current_condition[0];
                    root.tempC = current.temp_C;
                    root.conditionText = current.weatherDesc[0].value;
                    root.weatherCode = parseInt(current.weatherCode);
                    root.isStale = false;

                    cache.tempC = root.tempC;
                    cache.conditionText = root.conditionText;
                    cache.weatherCode = root.weatherCode;
                } catch (e) {}
            }
        }
    }

    GridLayout {
        id: row
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 999
        rowSpacing: 3
        columnSpacing: 5
        Text {
            text: root.iconGlyph
            font.family: root.iconFontFamily
            font.weight: Palette.Theme.iconWeight
            font.pixelSize: Palette.Theme.fontSizeBody
            color: Palette.Theme.textPrimary
            opacity: root.isStale ? 0.55 : 1.0
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }
        Text {
            text: root.tempC + (root.vertical ? "°" : "°C")
            color: Palette.Theme.textPrimary
            opacity: root.isStale ? 0.55 : 1.0
            font.family: Palette.Theme.fontMono
            font.pixelSize: root.vertical ? 12 : 13
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        }
    }
}
