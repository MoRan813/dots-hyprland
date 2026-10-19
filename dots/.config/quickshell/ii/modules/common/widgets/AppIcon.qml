import QtQuick
import Quickshell

// App icon, drawn from the icon file directly instead of through Kirigami.Icon.
//
// Why: with Kirigami.Icon the pixmap came back at the pixel density of the highest-DPI screen and
// was then painted at its natural device size. On the 1.8x panel that happened to equal the
// requested 18 logical px, but on a 1x output the same pixmap is ~1.8x too large for its box, so
// the surrounding circular mask (Colorizer + Circle in Workspaces.qml) clipped it down to the
// middle of the artwork. Sizing the source explicitly from the devicePixelRatio of the window we
// are actually drawn in keeps the painted size identical on every output — same approach as
// StyledImage.qml.
Item {
    id: root

    property real implicitSize: 26
    property string source: ""
    // Kept so existing call sites keep working; a plain Image has no icon-change fade.
    property bool animated: true
    property bool roundToIconSize: false

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Image {
        id: iconImage
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true

        source: {
            const s = root.source;
            if (!s || s.indexOf("://") >= 0)
                return s;
            return "file://" + s;
        }

        sourceSize: {
            const dpr = root.QsWindow.window?.devicePixelRatio ?? 1;
            return Qt.size(Math.round(root.width * dpr), Math.round(root.height * dpr));
        }
    }
}
