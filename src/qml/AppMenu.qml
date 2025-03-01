import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

MenuBar {
    id: menuBar
    MenuWithKbd {
        id: contextMenu
        title: "&Help"

        Action {
            text: "&Usage guide"
            shortcut: "F1"
            onTriggered: console.log("Usage Guide")
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
