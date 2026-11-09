import QtQuick

Item {
    id: root

    property string corner: "topLeft"
    property int size: 12
    property color color: "black"

    implicitWidth: size
    implicitHeight: size

    onCornerChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onVisibleChanged: if (visible)
            requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            var r = root.size;
            ctx.clearRect(0, 0, width, height);
            ctx.beginPath();

            switch (root.corner) {
            case "topLeft":
                ctx.arc(r, r, r, Math.PI, 3 * Math.PI / 2);
                ctx.lineTo(0, 0);
                break;
            case "topRight":
                ctx.arc(0, r, r, 3 * Math.PI / 2, 2 * Math.PI);
                ctx.lineTo(r, 0);
                break;
            case "bottomLeft":
                ctx.arc(r, 0, r, Math.PI / 2, Math.PI);
                ctx.lineTo(0, r);
                break;
            case "bottomRight":
                ctx.arc(0, 0, r, 0, Math.PI / 2);
                ctx.lineTo(r, r);
                break;
            }

            ctx.closePath();
            var c = root.color;
            ctx.fillStyle = "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")";
            ctx.fill();
        }
    }
}
