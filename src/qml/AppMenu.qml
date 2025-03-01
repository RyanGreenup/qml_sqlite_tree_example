import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

MenuBar {
    id: menuBar
    MenuWithKbd {
        id: contextMenu
        title: "&View"

        Action {
            text: "&Dark Mode"
            shortcut: "Ctrl+D"
            onTriggered: root.dark_mode = !root.dark_mode
        }
    }
}
