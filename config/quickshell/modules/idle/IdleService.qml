import Quickshell
import Quickshell.Io
import Quickshell.Wayland._IdleNotify
import QtQuick

Item {
    id: root

    required property var lockScreen

    readonly property bool keepAwake: keepAwakeState.keepAwake

    FileView {
        id: keepAwakeStateFile
        path: Quickshell.cachePath("idle-keepawake.json")
        watchChanges: false
        blockLoading: true

        JsonAdapter {
            id: keepAwakeState
            property bool keepAwake: false
        }
    }

    function toggleKeepAwake() {
        keepAwakeState.keepAwake = !keepAwakeState.keepAwake;
        keepAwakeStateFile.writeAdapter();
    }

    IdleMonitor {
        timeout: 350
        onIsIdleChanged: {
            if (isIdle) {
                if (!root.keepAwake)
                    dimOn.exec(["brightnessctl", "-s", "set", "10"]);
            } else
                dimOff.exec(["brightnessctl", "-r"]);
        }
    }

    IdleMonitor {
        timeout: 350
        onIsIdleChanged: {
            if (isIdle) {
                if (!root.keepAwake)
                    kbdOn.exec(["brightnessctl", "-sd", "rgb:kbd_backlight", "set", "0"]);
            } else
                kbdOff.exec(["brightnessctl", "-rd", "rgb:kbd_backlight"]);
        }
    }

    IdleMonitor {
        timeout: 400
        onIsIdleChanged: {
            if (isIdle && !root.keepAwake)
                root.lockScreen.lock();
        }
    }

    IdleMonitor {
        timeout: 500
        onIsIdleChanged: {
            if (isIdle) {
                if (!root.keepAwake)
                    dpmsOn.exec(["hyprctl", "dispatch", "dpms", "off"]);
            } else
                dpmsOff.exec(["sh", "-c", "hyprctl dispatch dpms on; brightnessctl -r"]);
        }
    }

    IdleMonitor {
        timeout: 1800
        onIsIdleChanged: {
            if (isIdle && !root.keepAwake)
                suspendProc.exec(["systemctl", "suspend"]);
        }
    }

    Process {
        id: dimOn
    }
    Process {
        id: dimOff
    }
    Process {
        id: kbdOn
    }
    Process {
        id: kbdOff
    }
    Process {
        id: dvdOn
    }
    Process {
        id: dvdOff
    }
    Process {
        id: dpmsOn
    }
    Process {
        id: dpmsOff
    }
    Process {
        id: suspendProc
    }

    Process {
        id: sleepWatcher
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        running: true

        property bool sawSignal: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.indexOf("member=PrepareForSleep") !== -1) {
                    sleepWatcher.sawSignal = true;
                    return;
                }
                if (!sleepWatcher.sawSignal)
                    return;
                sleepWatcher.sawSignal = false;
                if (data.indexOf("boolean true") !== -1)
                    root.lockScreen.lock();
                else if (data.indexOf("boolean false") !== -1)
                    dpmsOff.exec(["sh", "-c", "hyprctl dispatch dpms on; brightnessctl -r"]);
            }
        }

        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 3000
        onTriggered: sleepWatcher.running = true
    }
}
