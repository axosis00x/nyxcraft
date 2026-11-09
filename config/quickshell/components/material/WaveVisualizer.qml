import QtQuick
import "../../theme" as Palette

Canvas {
    id: root

    property var levels: []
    property color tint: Palette.Theme.accent
    property real attack: 0.3
    property real release: 0.3

    property var shown: []

    onLevelsChanged: animator.start()
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function soften(arr) {
        var n = arr.length;
        var out = [];
        for (var i = 0; i < n; i++) {
            var at = k => arr[Math.max(0, Math.min(n - 1, i + k))];
            out.push((at(-1) + 4 * at(0) + at(1)) / 6);
        }
        return out;
    }

    Timer {
        id: animator
        interval: 16
        repeat: true
        onTriggered: {
            var n = Math.max(root.levels.length, root.shown.length);
            var target = root.soften(root.levels);
            var next = [];
            var moving = false;
            for (var i = 0; i < n; i++) {
                var a = root.shown.length > i ? root.shown[i] : 0;
                var b = target.length > i ? target[i] : 0;
                var v = a + (b - a) * (b > a ? root.attack : root.release);
                if (Math.abs(b - v) > 0.002)
                    moving = true;
                else
                    v = b;
                next.push(v);
            }
            root.shown = next;
            root.requestPaint();
            if (!moving)
                stop();
        }
    }

    function hills(ctx, values) {
        var pts = [0].concat(values).concat([0]);
        var n = pts.length;
        var amp = height - 1;
        var step = width / (n - 1);
        var px = k => Math.max(0, Math.min(n - 1, k)) * step;
        var py = k => height - Math.max(1, pts[Math.max(0, Math.min(n - 1, k))] * amp);
        ctx.beginPath();
        ctx.moveTo(0, height);
        ctx.lineTo(px(0), py(0));
        for (var k = 0; k < n - 1; k++) {
            ctx.bezierCurveTo(px(k) + (px(k + 1) - px(k - 1)) / 6, py(k) + (py(k + 1) - py(k - 1)) / 6, px(k + 1) - (px(k + 2) - px(k)) / 6, py(k + 1) - (py(k + 2) - py(k)) / 6, px(k + 1), py(k + 1));
        }
        ctx.lineTo(width, height);
        ctx.closePath();
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        if (shown.length === 0)
            return;

        var fill = ctx.createLinearGradient(0, 0, 0, height);
        fill.addColorStop(0, Qt.alpha(tint, 0.95));
        fill.addColorStop(1, Qt.alpha(tint, 0.55));
        hills(ctx, shown);
        ctx.fillStyle = fill;
        ctx.fill();
    }
}
