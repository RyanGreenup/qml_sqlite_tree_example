import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

Dialog {
    id: newNoteDialog
    title: "Create New Note"
    modal: true
    closePolicy: Popup.CloseOnEscape
    width: Math.min(parent.width * 0.8, 600)
    height: Math.min(parent.height * 0.8, 500)
    anchors.centerIn: parent
    focus: true
    padding: 20

    // Some Custom Styling
    background: Rectangle {
        color: Universal.background
        border.color: Universal.accent
        border.width: 1
        radius: 6

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 3
            shadowBlur: 12
        }
    }

    // Blue header stripe
    header: Rectangle {
        color: Universal.accent
        height: 50
        radius: 5

        Label {
            text: newNoteDialog.title
            color: "white"
            font.pixelSize: 16
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
        }
    }

    // Store the input values
    property string noteTitle: titleField.text
    property string noteBody: bodyField.text
    property bool isModified: false

    // Signal emitted when the dialog is accepted
    signal noteCreated(string title, string body)

    // Custom footer; styled buttons
    footer: DialogButtonBox {
        alignment: Qt.AlignRight
        background: Rectangle {
            color: "transparent"
        }

        Button {
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            flat: true

            contentItem: Text {
                text: parent.text
                font.pixelSize: 14
                color: parent.hovered ? Universal.accent : Universal.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: 100
                implicitHeight: 40
                color: parent.hovered ? Qt.lighter(Universal.background, 1.1) : "transparent"
                border.color: parent.hovered ? Universal.accent : "transparent"
                border.width: 1
                radius: 4
            }
        }

        Button {
            id: saveButton
            text: "Save Note"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: titleField.text.trim() !== ""

            contentItem: Text {
                text: parent.text
                font.pixelSize: 14
                font.weight: Font.Medium
                color: parent.enabled ? "white" : Qt.darker("white", 1.5)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: 120
                implicitHeight: 40
                color: parent.enabled ? (parent.hovered ? Qt.lighter(Universal.accent, 1.1) : Universal.accent) : Qt.darker(Universal.accent, 1.5)
                radius: 4

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    onAccepted: {
        if (titleField.text.trim() !== "") {
            noteCreated(titleField.text, bodyField.text)
        }
    }

    // Handle key events for the dialog
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            reject()
            event.accepted = true
        } else if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
            if (titleField.text.trim() !== "") {
                accept()
                event.accepted = true
            }
        }
    }

    // Add key handlers to the text fields as well
    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: newNoteDialog.reject()
    }

    Shortcut {
        sequence: "Ctrl+Return"
        onActivated: {
            if (titleField.text.trim() !== "") {
                newNoteDialog.accept()
            }
        }
    }

    // Reset fields when dialog is opened
    onOpened: {
        titleField.text = "New Note"
        bodyField.text = ""
        isModified = false
        titleField.selectAll()
        titleField.forceActiveFocus()
    }

    contentItem: ColumnLayout {
        spacing: 16

        // Status bar showing keyboard shortcuts
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: Qt.rgba(Universal.accent.r, Universal.accent.g, Universal.accent.b, 0.1)
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Label {
                    text: "Ctrl+Enter to save • Esc to cancel"
                    font.pixelSize: 12
                    color: Universal.foreground
                    opacity: 0.7
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: isModified ? "Modified" : ""
                    font.pixelSize: 12
                    font.italic: true
                    color: Universal.accent
                }
            }
        }

        Label {
            text: "Title"
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
            Layout.topMargin: 10
            color: Universal.foreground
        }

        TextField {
            id: titleField
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: "Enter note title"
            selectByMouse: true
            font.pixelSize: 15

            background: Rectangle {
                color: titleField.activeFocus ? Qt.lighter(Universal.background, 1.1) : Universal.background
                border.color: titleField.activeFocus ? Universal.accent : Qt.darker(Universal.background, 1.2)
                border.width: 1
                radius: 4

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }

            onTextChanged: {
                isModified = true
            }

            // Select all text when focused
            onActiveFocusChanged: {
                if (activeFocus) {
                    selectAll()
                }
            }

            // Move to body field when Tab is pressed
            Keys.onTabPressed: {
                bodyField.forceActiveFocus()
                event.accepted = true
            }
        }

        Label {
            text: "Content"
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.fillWidth: true
            Layout.topMargin: 10
            color: Universal.foreground
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            background: Rectangle {
                color: bodyField.activeFocus ? Qt.lighter(Universal.background, 1.05) : Universal.background
                border.color: bodyField.activeFocus ? Universal.accent : Qt.darker(Universal.background, 1.2)
                border.width: 1
                radius: 4

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }

            TextArea {
                id: bodyField
                placeholderText: "Enter your note content here..."
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.pixelSize: 14
                padding: 10

                onTextChanged: {
                    isModified = true
                }

                // Move to title field when Shift+Tab is pressed
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                        titleField.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }
        }

        // Character count and word count
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5

                Label {
                    text: bodyField.text.length + " characters"
                    font.pixelSize: 12
                    opacity: 0.7
                }

                Label {
                    text: "•"
                    font.pixelSize: 12
                    opacity: 0.7
                }

                Label {
                    text: bodyField.text.trim() ? bodyField.text.trim().split(/\s+/).length + " words" : "0 words"
                    font.pixelSize: 12
                    opacity: 0.7
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: new Date().toLocaleString(Qt.locale(), "yyyy-MM-dd")
                    font.pixelSize: 12
                    opacity: 0.7
                }
            }
        }
    }
}
