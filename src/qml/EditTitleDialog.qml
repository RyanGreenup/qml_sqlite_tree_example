import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: editTitleDialog
    title: qsTr("Edit Title")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: 400

    // Signal emitted when the user confirms the edit
    signal titleEdited(string newTitle)

    // Property to store the current title
    property string currentTitle: ""

    // Center the dialog in the parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    // Set focus to the text field when the dialog opens
    onOpened: {
        titleField.text = currentTitle;
        titleField.forceActiveFocus();
        titleField.selectAll();
    }

    // Handle OK button click
    onAccepted: {
        if (titleField.text.trim() !== "") {
            titleEdited(titleField.text.trim());
        }
    }

    // Function to reset the dialog state
    function reset() {
        currentTitle = "";
    }

    // Content of the dialog
    contentItem: ColumnLayout {
        spacing: 10

        TextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: qsTr("Enter new title")
            selectByMouse: true
            
            // Allow pressing Enter to accept the dialog
            Keys.onReturnPressed: {
                if (text.trim() !== "") {
                    editTitleDialog.accept();
                }
            }
            Keys.onEnterPressed: {
                if (text.trim() !== "") {
                    editTitleDialog.accept();
                }
            }
        }
    }

    // Reset the field when the dialog is closed
    onClosed: {
        titleField.text = "";
    }
}
