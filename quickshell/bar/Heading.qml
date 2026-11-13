// Section title inside a dropdown ("Output", "Wi-Fi", …): small, dim.
// Put a control (Toggle, Chip) in it as a child: it sits at the right end.
import QtQuick
import qs

Item {
    id: root

    property string text
    property bool topGap: false                 // extra space above (between sections)
    default property alias control: slot.data

    implicitWidth: 340
    implicitHeight: Math.max(title.implicitHeight, slot.childrenRect.height) + (topGap ? 10 : 0)

    Label {
        id: title
        x: 10
        anchors.bottom: parent.bottom
        text: root.text
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: title.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
