import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"
import "../services/weather"

PanelWindow {
    id: root

    property var widgetsService: null

    readonly property bool clockOn: widgetsService ? widgetsService.isEnabled("clock") : true
    readonly property bool weatherOn: widgetsService ? widgetsService.isEnabled("weather") : true
    readonly property bool cavaOn: widgetsService ? widgetsService.isEnabled("cava") : true

    readonly property real margin: 36
    readonly property real spacing: 16

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:desktop-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: root.clockOn || root.weatherOn || root.cavaOn

    mask: Region {
        Region {
            x: clockWidget.x
            y: clockWidget.y
            width: clockWidget.width * clockWidget.scale
            height: clockWidget.height * clockWidget.scale
            intersection: Intersection.Combine
        }
        Region {
            x: weatherWidget.x
            y: weatherWidget.y
            width: weatherWidget.width * weatherWidget.scale
            height: weatherWidget.height * weatherWidget.scale
            intersection: Intersection.Combine
        }
        Region {
            x: cavaWidget.x
            y: cavaWidget.y
            width: cavaWidget.width * cavaWidget.scale
            height: cavaWidget.height * cavaWidget.scale
            intersection: Intersection.Combine
        }
    }

    readonly property var weatherService: WeatherService

    ClockWidget {
        id: clockWidget
        widgetsService: root.widgetsService
        visible: root.clockOn

        defaultX: root.width - root.margin - (weatherWidget.implicitWidth + clockWidget.implicitWidth) / 2
        defaultY: root.height - root.margin - root.spacing - clockWidget.implicitHeight - weatherWidget.implicitHeight
    }

    WeatherWidget {
        id: weatherWidget
        service: weatherService
        widgetsService: root.widgetsService
        visible: root.weatherOn
        defaultX: root.width - root.margin - weatherWidget.implicitWidth
        defaultY: root.height - root.margin - weatherWidget.implicitHeight
    }

    CavaWaveWidget {
        id: cavaWidget
        widgetsService: root.widgetsService
        visible: root.cavaOn
        defaultX: root.margin
        defaultY: root.height - root.margin - cavaWidget.implicitHeight
    }
}
