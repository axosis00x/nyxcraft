import QtQuick

Item {
    id: root

    property color color: "white"
    property int lobes: 6
    property real amplitude: 0.08

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = root.color;

            var cx = width / 2;
            var cy = height / 2;
            var R = Math.min(width, height) / 2;
            var baseR = R / (1 + root.amplitude);
            var steps = 200;

            ctx.beginPath();
            for (var i = 0; i <= steps; i++) {
                var theta = (i / steps) * Math.PI * 2;
                var r = baseR * (1 + root.amplitude * Math.cos(root.lobes * theta));
                var x = cx + r * Math.cos(theta);
                var y = cy + r * Math.sin(theta);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            ctx.fill();
        }
    }

    onColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onLobesChanged: canvas.requestPaint()
    onAmplitudeChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()
}
