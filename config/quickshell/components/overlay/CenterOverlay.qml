import Quickshell
import Quickshell.Wayland
import QtQuick
import "../material"
import "../../modules/launcher"
import "../../modules/controlcenter"
import "../../modules/powermenu"
import "../../modules/polkit"
import "../../modules/theme"
import "../../modules/clipboard"
import "../../modules/servicemanager"
import "../../modules/bar"
import "../../modules/calendar"
import "../../modules/toolmenu"
import "../../modules/barlayout"
import "../../modules/wallpicker"
import "../../modules/dock"
import "../../services"
import "../../components/material"
import "../../theme" as Palette

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "transparent"
    mask: Region {
        Region {
            width: root.active ? root.width : 0
            height: root.active ? root.height : 0
            intersection: Intersection.Combine
        }
        Region {
            item: root.dockShown ? bottomStage : null
            intersection: Intersection.Combine
        }
        Region {
            item: root.dockAutoHidden ? dockTrigger : null
            intersection: Intersection.Combine
        }
        Region {
            item: dockPopups.menuVisible ? dockPopups.menuRect : null
            intersection: Intersection.Combine
        }

        Region {
            item: root.peekPanel ? topStage : null
            intersection: Intersection.Combine
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-center-overlay"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var bar: null
    property var notificationCenter: null
    property var idleService: null
    property var barLayout: null
    property var widgetsService: null
    property var settingsWindow: null
    readonly property bool verticalBar: barLayout ? barLayout.vertical : false
    readonly property bool active: (activeTopPanel !== null) || (activeBottomPanel !== null)

    readonly property int closeDuration: (Palette.Theme.motionFast + Palette.Theme.motionDefault) / 2

    readonly property var peekPanel: activeTopPanel !== null ? null : (notificationPeek.wanted ? notificationPeek : (liveActivity.wanted && !fullscreenActive ? liveActivity : null))

    function isTopModule(panel) {
        return panel === controlCenterItem || panel === powerMenuItem || panel === toolMenuItem || panel === mediaPanelItem || panel === polkitItem;
    }

    property var currentTargetPanel: null

    readonly property var activeTopPanel: currentTargetPanel && currentTargetPanel.visible && isTopModule(currentTargetPanel) ? currentTargetPanel : null
    readonly property var activeBottomPanel: currentTargetPanel && currentTargetPanel.visible && !isTopModule(currentTargetPanel) ? currentTargetPanel : null

    property bool dockRevealed: false
    readonly property bool dockCanShow: dockItem.wanted && activeBottomPanel === null
    readonly property bool dockShown: dockCanShow && (!Palette.Theme.dockAutoHide || !dockItem.workspaceBusy || dockRevealed)
    readonly property bool dockAutoHidden: dockCanShow && !dockShown
    readonly property bool dockPointerInside: dockTrigger.hovered || dockItem.holdOpen

    onDockPointerInsideChanged: {
        if (dockPointerInside) {
            dockHideTimer.stop();
            dockRevealed = true;
        } else {
            dockHideTimer.restart();
        }
    }

    Timer {
        id: dockHideTimer
        interval: 450
        onTriggered: root.dockRevealed = false
    }

    Item {
        id: dockTrigger

        readonly property bool hovered: triggerHover.hovered

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(360, dockItem.implicitWidth + 120)
        height: 6

        HoverHandler {
            id: triggerHover
        }
    }

    property alias launcher: launcherItem
    property alias controlCenter: controlCenterItem
    property alias powerMenu: powerMenuItem
    property alias themePicker: themePickerItem
    property alias clipboard: clipboardItem
    property alias serviceManager: serviceManagerItem
    property alias mediaPanel: mediaPanelItem
    property alias toolMenu: toolMenuItem
    property alias calendarPicker: calendarPickerItem
    property alias barLayoutPicker: barLayoutPickerItem
    property alias wallpaperPicker: wallpaperPickerItem
    property alias themes: themeService

    function presentOnly(panel) {
        currentTargetPanel = panel;
        if (panel !== launcherItem && launcherItem.visible)
            launcherItem.closeLauncher();
        if (panel !== controlCenterItem && controlCenterItem.visible)
            controlCenterItem.closeControlCenter();
        if (panel !== powerMenuItem && powerMenuItem.visible)
            powerMenuItem.closePowerMenu();
        if (panel !== themePickerItem && themePickerItem.visible)
            themePickerItem.close();
        if (panel !== clipboardItem && clipboardItem.visible)
            clipboardItem.close();
        if (panel !== serviceManagerItem && serviceManagerItem.visible)
            serviceManagerItem.close();
        if (panel !== mediaPanelItem && mediaPanelItem.visible)
            mediaPanelItem.close();
        if (panel !== toolMenuItem && toolMenuItem.visible)
            toolMenuItem.closeToolMenu();
        if (panel !== calendarPickerItem && calendarPickerItem.visible)
            calendarPickerItem.close();
        if (panel !== barLayoutPickerItem && barLayoutPickerItem.visible)
            barLayoutPickerItem.close();
        if (panel !== wallpaperPickerItem && wallpaperPickerItem.visible)
            wallpaperPickerItem.close();
        if (panel !== polkitItem && polkitItem.visible)
            polkitItem.close();
    }

    function closeActive() {
        const panel = activeTopPanel || activeBottomPanel;
        if (panel === launcherItem)
            launcherItem.closeLauncher();
        else if (panel === controlCenterItem)
            controlCenterItem.closeControlCenter();
        else if (panel === powerMenuItem)
            powerMenuItem.closePowerMenu();
        else if (panel === themePickerItem)
            themePickerItem.close();
        else if (panel === clipboardItem)
            clipboardItem.close();
        else if (panel === serviceManagerItem)
            serviceManagerItem.close();
        else if (panel === mediaPanelItem)
            mediaPanelItem.close();
        else if (panel === toolMenuItem)
            toolMenuItem.closeToolMenu();
        else if (panel === calendarPickerItem)
            calendarPickerItem.close();
        else if (panel === barLayoutPickerItem)
            barLayoutPickerItem.close();
        else if (panel === wallpaperPickerItem)
            wallpaperPickerItem.close();
        else if (panel === polkitItem)
            polkitItem.close();
    }

    ThemeService {
        id: themeService
    }

    ShaderService {
        id: shaderService
    }

    WayclickService {
        id: wayclickService
    }

    ClipboardService {
        id: clipboardService
    }

    MouseArea {
        anchors.fill: parent
        visible: root.active
        onClicked: root.closeActive()
    }

    readonly property real barSlabWidth: bar ? (bar.centerCapsuleSlabWidth || 120) : 120
    readonly property bool island: barLayout ? barLayout.island : false

    readonly property real barSlabHeight: root.verticalBar ? 0 : (bar ? bar.height - (root.island ? bar.islandGap : Palette.Theme.screenFrameBorder) : 34)

    readonly property bool fullscreenActive: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.fullscreen : false
    readonly property bool framed: barLayout ? (barLayout.loaded && !root.island && !fullscreenActive) : false
    property real frameInset: framed ? Palette.Theme.screenFrameBorder : 0
    property real topFrameInset: framed ? Palette.Theme.screenFrameBorder : 0
    Behavior on topFrameInset {
        EffectMotion {}
    }
    Behavior on frameInset {
        EffectMotion {}
    }

    readonly property color stageColor: Palette.Theme.bg
    readonly property real stageTint: 0
    readonly property real stageWing: framed ? Palette.Theme.screenFrameRadius : 9

    Notch {
        id: topStage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topFrameInset
        bottomAligned: false
        island: root.island
        islandGap: bar ? bar.islandGap : 4
        wingSize: root.stageWing

        slabRadius: sized === null || sized === liveActivity ? (root.bar ? root.bar.capsuleRadius : Palette.Theme.radiusSmall) : Palette.Theme.radiusLarge
        color: root.stageColor
        tintOpacity: root.stageTint

        Behavior on slabRadius {
            SpatialMotion {
                easing.type: topStage.shrinking ? Easing.OutCubic : Easing.OutBack
                duration: topStage.shrinking ? root.closeDuration : Palette.Theme.motionDefault
            }
        }
        Behavior on color {
            ColorMotion {}
        }

        readonly property var panel: root.activeTopPanel || root.peekPanel

        property var sized: null
        property bool shrinking: false

        onPanelChanged: {
            shrinking = panel === null || (panel === root.peekPanel && sized !== null && sized !== root.peekPanel && sized !== notificationPeek && sized !== liveActivity);
            settling = panel === null && sized !== null;
            settling ? settleTimer.restart() : settleTimer.stop();
            sized = panel;
        }
        Component.onCompleted: sized = panel

        slabWidth: sized === liveActivity ? Math.max(liveActivity.implicitWidth, root.barSlabWidth) : (sized ? sized.implicitWidth : root.barSlabWidth)
        slabHeight: sized ? sized.implicitHeight : root.barSlabHeight
        property bool settling: false
        opacity: panel || settling ? 1 : 0

        Timer {
            id: settleTimer
            interval: root.closeDuration
            onTriggered: topStage.settling = false
        }

        Behavior on slabWidth {
            enabled: !root.barLayout || root.barLayout.loaded
            SpatialMotion {
                easing.type: topStage.shrinking ? Easing.OutCubic : Easing.OutBack
                duration: topStage.shrinking ? root.closeDuration : Palette.Theme.motionDefault
            }
        }
        Behavior on slabHeight {
            enabled: !root.barLayout || root.barLayout.loaded
            SpatialMotion {
                easing.type: topStage.shrinking ? Easing.OutCubic : Easing.OutBack
                duration: topStage.shrinking ? root.closeDuration : Palette.Theme.motionDefault
            }
        }
        Behavior on opacity {
            EffectMotion {}
        }

        ControlCenter {
            id: controlCenterItem
            maxWidth: root.width
            maxHeight: root.height
            notificationCenter: root.notificationCenter
            bar: root.bar
            idleService: root.idleService
            media: mediaPanelItem
        }

        PowerMenu {
            id: powerMenuItem
            maxWidth: root.width
            launcher: launcherItem
            controlCenter: controlCenterItem
        }

        ToolMenu {
            id: toolMenuItem
            maxWidth: root.width
            launcher: launcherItem
            controlCenter: controlCenterItem
            bar: root.bar
        }

        MediaPanel {
            id: mediaPanelItem
            island: root.island
        }

        PolkitPanel {
            id: polkitItem
            maxWidth: root.width
        }

        NotificationPeek {
            id: notificationPeek
            center: root.notificationCenter
        }

        LiveActivity {
            id: liveActivity
            bar: root.bar
            baseHeight: root.barSlabHeight
        }
    }

    Binding {
        target: root.bar
        property: "centerActivityVisible"
        value: root.peekPanel === liveActivity
        when: root.bar !== null
    }

    Notch {
        id: bottomStage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.frameInset
        bottomAligned: true
        island: root.island
        islandGap: 8
        wingSize: root.stageWing
        slabRadius: Palette.Theme.radiusLarge
        color: root.stageColor
        tintOpacity: root.stageTint

        Behavior on color {
            ColorMotion {}
        }

        readonly property var panel: root.activeBottomPanel ? root.activeBottomPanel : (root.dockShown ? dockItem : null)

        property var sized: null
        property bool shrinking: false
        onPanelChanged: {
            shrinking = panel === null || panel === dockItem;
            settling = panel === null && sized !== null;
            settling ? bottomSettleTimer.restart() : bottomSettleTimer.stop();
            sized = panel;
        }
        Component.onCompleted: sized = panel

        slabWidth: sized ? sized.implicitWidth : 120
        slabHeight: sized ? sized.implicitHeight : 0
        property bool settling: false
        opacity: panel || settling ? 1 : 0

        Timer {
            id: bottomSettleTimer
            interval: root.closeDuration
            onTriggered: bottomStage.settling = false
        }

        Behavior on slabWidth {
            SpatialMotion {
                easing.type: bottomStage.shrinking ? Easing.OutCubic : Easing.OutBack
                duration: bottomStage.shrinking ? root.closeDuration : Palette.Theme.motionDefault
            }
        }
        Behavior on slabHeight {
            SpatialMotion {
                easing.type: bottomStage.shrinking ? Easing.OutCubic : Easing.OutBack
                duration: bottomStage.shrinking ? root.closeDuration : Palette.Theme.motionDefault
            }
        }
        Behavior on opacity {
            EffectMotion {}
        }

        Dock {
            id: dockItem

            visible: bottomStage.panel === dockItem || dockSlot.reveal > 0
            maxWidth: root.width
            widgetsService: root.widgetsService
        }

        Launcher {
            id: launcherItem
            maxWidth: root.width
            controlCenter: controlCenterItem
            serviceManager: serviceManagerItem
            shaderService: shaderService
            wayclickService: wayclickService
            widgetsService: root.widgetsService
            settingsWindow: root.settingsWindow
        }

        ThemePicker {
            id: themePickerItem
            maxWidth: root.width
            maxHeight: root.height
            service: themeService
            launcher: launcherItem
            controlCenter: controlCenterItem
            powerMenu: powerMenuItem
        }

        Clipboard {
            id: clipboardItem
            maxWidth: root.width
            maxHeight: root.height
            service: clipboardService
        }

        ServiceManager {
            id: serviceManagerItem
            maxWidth: root.width
            maxHeight: root.height
        }

        CalendarPanel {
            id: calendarPickerItem
            maxWidth: root.width
            maxHeight: root.height
        }

        BarLayoutPicker {
            id: barLayoutPickerItem
            maxWidth: root.width
            service: root.barLayout
            launcher: launcherItem
            controlCenter: controlCenterItem
            powerMenu: powerMenuItem
        }

        WallpaperPicker {
            id: wallpaperPickerItem
            maxWidth: root.width
            maxHeight: root.height
            launcher: launcherItem
            controlCenter: controlCenterItem
            powerMenu: powerMenuItem
            themeService: themeService
        }
    }

    StageSlot {
        panel: controlCenterItem
        stage: topStage
    }
    StageSlot {
        panel: powerMenuItem
        stage: topStage
    }
    StageSlot {
        panel: toolMenuItem
        stage: topStage
    }
    StageSlot {
        panel: mediaPanelItem
        stage: topStage
    }
    StageSlot {
        panel: polkitItem
        stage: topStage
    }
    StageSlot {
        panel: notificationPeek
        stage: topStage
    }
    StageSlot {
        panel: liveActivity
        stage: topStage
    }
    StageSlot {
        id: dockSlot
        panel: dockItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: launcherItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: themePickerItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: clipboardItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: serviceManagerItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: calendarPickerItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: barLayoutPickerItem
        stage: bottomStage
        fromBottom: true
    }
    StageSlot {
        panel: wallpaperPickerItem
        stage: bottomStage
        fromBottom: true
    }

    DockPopups {
        id: dockPopups
        dock: dockItem
    }

    Connections {
        target: launcherItem
        function onAboutToOpen() {
            root.presentOnly(launcherItem);
        }
    }
    Connections {
        target: controlCenterItem
        function onAboutToOpen() {
            root.presentOnly(controlCenterItem);
        }
    }
    Connections {
        target: powerMenuItem
        function onAboutToOpen() {
            root.presentOnly(powerMenuItem);
        }
    }
    Connections {
        target: themePickerItem
        function onAboutToOpen() {
            root.presentOnly(themePickerItem);
        }
    }
    Connections {
        target: clipboardItem
        function onAboutToOpen() {
            root.presentOnly(clipboardItem);
        }
    }
    Connections {
        target: serviceManagerItem
        function onAboutToOpen() {
            root.presentOnly(serviceManagerItem);
        }
    }
    Connections {
        target: mediaPanelItem
        function onAboutToOpen() {
            root.presentOnly(mediaPanelItem);
        }
    }
    Connections {
        target: toolMenuItem
        function onAboutToOpen() {
            root.presentOnly(toolMenuItem);
        }
    }
    Connections {
        target: calendarPickerItem
        function onAboutToOpen() {
            root.presentOnly(calendarPickerItem);
        }
    }
    Connections {
        target: barLayoutPickerItem
        function onAboutToOpen() {
            root.presentOnly(barLayoutPickerItem);
        }
    }
    Connections {
        target: wallpaperPickerItem
        function onAboutToOpen() {
            root.presentOnly(wallpaperPickerItem);
        }
    }
    Connections {
        target: polkitItem
        function onAboutToOpen() {
            root.presentOnly(polkitItem);
        }
    }
}
