// Text with the theme font and colour already set.
import QtQuick
import qs

Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    textFormat: Text.PlainText      // notification text must not render as markup
    elide: Text.ElideRight
    maximumLineCount: 1
}
