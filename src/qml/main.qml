import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

ApplicationWindow {
    id: root
    // Custom handle component for SplitView
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"
    property int border_width
    property bool dark_mode
    Universal.theme: root.dark_mode ? Universal.Dark : Universal.Light

    // Menu Bar
    menuBar: AppMenu {}

    // The Main View
    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
            SplitView.preferredWidth: parent.width * 0.39
            color: Universal.background
            border.color: Universal.accent

            // Make sure to only focus treeView
            border.width: treeView.activeFocus ? 10 : 0
            focus: false
            activeFocusOnTab: false

            MyTreeView {
                id: treeView
                anchors.fill: parent
                topMargin: root.border_width + 2
                leftMargin: root.border_width + 2

                // Connect to the signal to log statistics when item changes
                onCurrentItemChanged: function (note_body) {
                    console.log("Current item changed. Statistics:", note_body);
                }
            }
        }

        Rectangle {
            id: detailsRect
            SplitView.preferredWidth: parent.width * 0.61
            color: Universal.background

            // Allow Focus
            focus: true
            activeFocusOnTab: true
            border.width: activeFocus ? 10 : 0
            border.color: Universal.accent

            // Display area for the current item statistics
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10

                Label {
                    text: "TODO Note Title"
                    font.bold: true
                    font.pointSize: 12
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: noteBody
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        text: "Select an item in the tree to view statistics"

                        background: Rectangle {
                            color: Universal.background
                            border.color: Universal.accent
                            border.width: 1
                            radius: 4
                        }
                    }
                }
            }

            // Connect to the tree view's signal
            Connections {
                target: treeView
                /**
                 * Updates the text of the noteBody element with the provided note body text.
                 *
                 * @param {string} note_body_text - The text to be set as the note body.
                 */
                function onCurrentItemChanged(note_body) {
                    noteBody.text = note_body;
                }
            }
        }
    }
}
