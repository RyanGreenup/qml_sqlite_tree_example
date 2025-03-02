import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window

Dialog {
    // Remove explicit theme setting to inherit from parent
    id: newNoteDialog
    title: "Create New Note"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: Math.min(parent.width * 0.8, 500)
    height: Math.min(parent.height * 0.8, 400)
    anchors.centerIn: parent
    focus: true

    // Properties to store the input values
    property string noteTitle: titleField.text
    property string noteBody: bodyField.text

    // Signal emitted when the dialog is accepted with valid data
    signal noteCreated(string title, string body)

    onAccepted: {
        if (titleField.text.trim() !== "") {
            noteCreated(titleField.text, bodyField.text);
        }
    }

    // Handle key events for the dialog
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            reject();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
            accept();
            event.accepted = true;
        }
    }

    // Add key handlers to the text fields as well
    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: newNoteDialog.reject()
    }

    Shortcut {
        sequence: "Ctrl+Return"
        onActivated: newNoteDialog.accept()
    }

    // Reset fields when dialog is opened
    onOpened: {
        titleField.text = "New Note";
        bodyField.text = "Enter your note here...";
        titleField.selectAll();
        titleField.forceActiveFocus();
    }

    contentItem: ColumnLayout {
        spacing: 10

        Label {
            text: "Title:"
            Layout.fillWidth: true
        }

        TextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: "Enter note title"
            selectByMouse: true

            // Select all text when focused
            onActiveFocusChanged: {
                if (activeFocus) {
                    selectAll();
                }
            }

            // Move to body field when Tab is pressed
            Keys.onTabPressed: function(event) {
                bodyField.forceActiveFocus();
                event.accepted = true;
            }
        }

        Label {
            text: "Content:"
            Layout.fillWidth: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea {
                id: bodyField
                placeholderText: "Enter note content"
                wrapMode: TextEdit.Wrap
                selectByMouse: true

                // Move to title field when Shift+Tab is pressed
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                        titleField.forceActiveFocus();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
