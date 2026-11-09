import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    property bool running: false

    property real cpu: 0
    property real memory: 0
    property real disk: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0

    property real temperature: 0
    readonly property real temperatureFraction: Math.min(1, temperature / 100)

    property var lastCpu: null

    function gib(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    Timer {
        interval: 2000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sample.running)
                sample.running = true;
        }
    }

    Timer {
        id: secondSample
        interval: 350
        onTriggered: {
            if (!sample.running)
                sample.running = true;
        }
    }
    onRunningChanged: if (!running)
        lastCpu = null

    Timer {
        interval: 30000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!diskRead.running)
                diskRead.running = true;
        }
    }

    Process {
        id: sample
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; " + "t=''; for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat \"$z/type\" 2>/dev/null)\" = x86_pkg_temp ] && t=$(cat \"$z/temp\"); done; " + "[ -n \"$t\" ] || t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1); echo \"temp ${t:-0}\""]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: diskRead
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n").pop().trim().split(/\s+/);
                root.diskUsed = Number(parts[0]) || 0;
                root.diskTotal = Number(parts[1]) || 0;
                root.disk = root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0;
            }
        }
    }

    function parse(text) {
        var memTotal = 0, memAvailable = 0;
        text.split("\n").forEach(line => {
            var f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                var values = f.slice(1).map(Number);
                var idle = values[3] + (values[4] || 0);
                var total = values.reduce((a, b) => a + b, 0);
                if (root.lastCpu) {
                    var dTotal = total - root.lastCpu.total;
                    var dIdle = idle - root.lastCpu.idle;
                    root.cpu = dTotal > 0 ? Math.max(0, Math.min(1, 1 - dIdle / dTotal)) : 0;
                }
                if (!root.lastCpu)
                    secondSample.restart();
                root.lastCpu = {
                    total: total,
                    idle: idle
                };
            } else if (f[0] === "MemTotal:") {
                memTotal = Number(f[1]) * 1024;
            } else if (f[0] === "MemAvailable:") {
                memAvailable = Number(f[1]) * 1024;
            } else if (f[0] === "temp") {
                root.temperature = (Number(f[1]) || 0) / 1000;
            }
        });
        if (memTotal > 0) {
            root.memoryTotal = memTotal;
            root.memoryUsed = memTotal - memAvailable;
            root.memory = root.memoryUsed / memTotal;
        }
    }
}
