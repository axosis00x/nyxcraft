import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Item {
    id: root

    property string passwordBuffer: ""

    property string typed: ""
    property bool authBusy: false
    property bool authFailed: false
    property int failedAttempts: 0
    property string wallpaperPath: ""

    property string depthPath: ""

    readonly property string lockscreenDir: Quickshell.env("HOME") + "/Pictures/wallpapers/lockscreen"
    readonly property string depthScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/depth-cutout.sh"

    onWallpaperPathChanged: {
        depthPath = "";
        if (wallpaperPath.indexOf(lockscreenDir + "/") === 0)
            depthRead.exec([depthScript, wallpaperPath]);
    }

    readonly property bool isLocked: sessionLock.locked && sessionLock.secure

    signal unlocked
    signal engaged

    function refreshWallpaper() {
        wallpaperRead.running = true;
    }

    function lock() {
        if (sessionLock.locked)
            return;
        root.passwordBuffer = "";
        root.typed = "";
        root.authFailed = false;
        root.authBusy = false;
        root.failedAttempts = 0;
        refreshWallpaper();
        if (!depthWarm.running)
            depthWarm.running = true;
        sessionLock.locked = true;
        root.engaged();

        lockHint.exec(["loginctl", "lock-session"]);
    }

    function submitTyped() {
        var pw = root.typed;
        root.typed = "";
        root.submit(pw);
    }

    function submit(password) {
        if (password === "" || root.authBusy)
            return;
        root.passwordBuffer = password;
        root.authFailed = false;
        root.authBusy = true;
        if (!pam.start()) {
            root.authBusy = false;
            root.authFailed = true;
            root.passwordBuffer = "";
        }
    }

    PamContext {
        id: pam
        config: "login"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.passwordBuffer);
        }

        onCompleted: result => {
            root.authBusy = false;
            root.passwordBuffer = "";
            if (result === PamResult.Success) {
                sessionLock.locked = false;
            } else {
                root.authFailed = true;
                root.failedAttempts += 1;
            }
        }

        onError: error => {
            root.authBusy = false;
            root.authFailed = true;
            root.passwordBuffer = "";
        }
    }

    Timer {
        interval: 3000
        running: sessionLock.locked && !sessionLock.secure
        onTriggered: sessionLock.locked = false
    }

    WlSessionLock {
        id: sessionLock

        onLockedChanged: {
            if (!locked)
                root.unlocked();
        }

        surface: Component {
            LockSurface {
                lockScreen: root
            }
        }
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void {
            root.lock();
        }
    }

    Process {
        id: lockHint
    }

    Process {
        id: wallpaperRead

        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/lockscreen-wallpaper.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpaperPath = text.trim();
            }
        }
    }

    Process {
        id: depthRead
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim();

                if (path !== "" && !depthRead.running)
                    root.depthPath = path;
            }
        }
    }

    Process {
        id: depthWarm
        command: ["nice", "-n", "19", root.depthScript, "--all", root.lockscreenDir]
    }

    Component.onCompleted: {
        refreshWallpaper();
        depthWarm.running = true;
    }
}
