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
            text: "&Usage guide"
            shortcut: "Ctrl+D"
            onTriggered: root.dark_mode = !root.dark_mode
        }
    }
    MenuWithKbd {
        id: menuEdit
        title: qsTr("&Edit")
        Action {
            text: qsTr("&Undo")
            shortcut: "Ctrl+U"
            onTriggered: console.log("Undo Triggered")
        }
    }
}
