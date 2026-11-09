//@ pragma DropExpensiveFonts
import Quickshell
import Quickshell.Io
import QtQuick
import "modules/bar"
import "components/overlay"
import "modules/notification"
import "modules/osd"
import "modules/workspaces"
import "modules/lockscreen"
import "modules/idle"
import "services"
import "widgets"
import "modules/settings"

ShellRoot {
    id: root
    NotificationCenter {
        id: notificationCenter
    }
    BarLayoutService {
        id: barLayoutService
    }
    WidgetsService {
        id: widgetsService
    }
    DesktopWidgetsLayer {
        widgetsService: widgetsService
    }
    CenterOverlay {
        id: overlay
        notificationCenter: notificationCenter
        bar: barLoader.item
        idleService: idleService
        barLayout: barLayoutService
        settingsWindow: settingsWindow
        widgetsService: widgetsService
    }

    ShellSettings {
        id: shellSettings
    }
    SettingsWindow {
        id: settingsWindow
        shellSettings: shellSettings
        controlCenter: overlay.controlCenter
        widgetsService: widgetsService
        themeService: overlay.themes
        barLayout: barLayoutService

        onAboutToOpen: overlay.closeActive()
    }
    WorkspacesService {
        id: workspacesServiceInstance
    }
    WorkspaceOverview {
        id: workspaceOverview
        service: workspacesServiceInstance
    }
    Osd {
        id: mainOsd
    }

    ScreenFrame {
        barLayout: barLayoutService
    }
    LockScreen {
        id: lockScreen
    }

    Binding {
        target: Quickshell
        property: "watchFiles"
        value: !lockScreen.isLocked
    }
    IdleService {
        id: idleService
        lockScreen: lockScreen
    }
    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            root.toggleControlCenter();
        }
        function open(): void {
            root.openControlCenter();
        }
        function close(): void {
            root.closeControlCenter();
        }

        function tab(name: string): void {
            if (overlay.controlCenter)
                overlay.controlCenter.openTab(name);
        }

        function wifi(): void {
            root.openControlCenterDetail("wifi");
        }
        function bluetooth(): void {
            root.openControlCenterDetail("bluetooth");
        }
    }
    function openControlCenterDetail(mode) {
        var c = overlay.controlCenter;
        if (!c)
            return;
        c.openControlCenter();
        c.detailMode = mode;
    }
    function openControlCenter() {
        if (overlay.controlCenter)
            overlay.controlCenter.openControlCenter();
    }
    function closeControlCenter() {
        if (overlay.controlCenter)
            overlay.controlCenter.closeControlCenter();
    }
    function toggleControlCenter() {
        if (overlay.controlCenter)
            overlay.controlCenter.toggleControlCenter();
    }
    IpcHandler {
        target: "mediapanel"
        function toggle(): void {
            root.toggleMediaPanel();
        }
    }
    function toggleMediaPanel() {
        if (overlay.mediaPanel)
            overlay.mediaPanel.toggleMediaPanel();
    }
    IpcHandler {
        target: "shell"
        function reload(): void {
            if (!lockScreen.isLocked)
                Quickshell.reload(false);
        }
    }

    Loader {
        id: barLoader
        active: barLayoutService.loaded

        sourceComponent: Bar {
            osd: mainOsd
            barLayout: barLayoutService
            widgetService: widgetsService
            workspacesService: workspacesServiceInstance
            launcher: overlay.launcher
            controlCenter: overlay.controlCenter
            powerMenu: overlay.powerMenu
            themePicker: overlay.themePicker
            clipboard: overlay.clipboard
            mediaPanel: overlay.mediaPanel
            toolMenu: overlay.toolMenu
            calendarPicker: overlay.calendarPicker
            ensureControlCenter: function () {
                return overlay.controlCenter;
            }
        }
    }
}
