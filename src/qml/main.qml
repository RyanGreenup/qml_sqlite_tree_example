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

    // Menu with a delegate to show Keyboard Shortcuts
    component MenuWithKbd: Menu {
        id: my_menu
        delegate: MenuItem {
            id: control

            contentItem: Item {
                anchors.centerIn: parent

                function transformString(inputString) {
                    // Find the index of '&' in the input string
                    const ampIndex = inputString.indexOf('&');

                    if (ampIndex !== -1 && ampIndex + 1 < inputString.length) {
                        // Get the character following '&'
                        const charToUnderline = inputString.charAt(ampIndex + 1);

                        // Construct the new string with the character underlined
                        const transformedString = inputString.slice(0, ampIndex) + `<u>${charToUnderline}</u>` + inputString.slice(ampIndex + 2);

                        return transformedString;
                    }

                    // Return the original string if no '&' is present
                    return inputString;
                }

                Text {
                    text: transformString(control.text)
                    // text: "My <u>S</u>tring"
                    anchors.left: parent.left
                    // color: "white"
                }

                Text {
                    text: control.action.shortcut
                    anchors.right: parent.right
                    // color: "white"
                }
            }
        }
    }

    // Menu Bar
    menuBar: MenuBar {
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

    // Tree Delegate to display Tree Items
    component MyTreeDelegate: Item {
        id: tree_delegate
        implicitWidth: padding + label.x + label.implicitWidth + padding
        implicitHeight: label.implicitHeight * 1.5

        readonly property real indentation: 20
        readonly property real padding: 5

        // Assigned to by TreeView:
        required property TreeView treeView
        required property bool isTreeNode
        required property bool expanded
        required property bool hasChildren
        required property int depth
        required property int row
        required property int column
        required property bool current
        required property string display

        // Rotate indicator when expanded by the user
        // (requires TreeView to have a selectionModel)
        property Animation indicatorAnimation: NumberAnimation {
            target: indicator
            property: "rotation"
            from: tree_delegate.expanded ? 0 : 90
            to: tree_delegate.expanded ? 90 : 0
            duration: 200
            easing.type: Easing.OutQuart
        }
        TableView.onPooled: indicatorAnimation.complete()
        TableView.onReused: if (current)
            indicatorAnimation.start()
        onExpandedChanged: indicator.rotation = expanded ? 90 : 0

        function is_current_item() {
            return tree_delegate.row === tree_delegate.treeView.currentRow;
        }

        // Handle right-click to show context menu
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: function (eventPoint) {
                // tree_delegate.treeView.currentRow = tree_delegate.row;
                contextMenu.x = eventPoint.position.x;
                contextMenu.y = eventPoint.position.y;
                contextMenu.open();
            }
        }

        function item_opacity() {
            if (tree_delegate.is_current_item()) {
                return 1;
            }
            if (tree_delegate.treeView.alternatingRows && tree_delegate.row % 2 !== 0) {
                return 0.1;
            } else {
                return 0;
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: tree_delegate.is_current_item() ? palette.highlight : Universal.accent
            opacity: tree_delegate.item_opacity()
        }

        Label {
            id: indicator
            x: padding + (tree_delegate.depth * tree_delegate.indentation)
            anchors.verticalCenter: parent.verticalCenter
            visible: tree_delegate.isTreeNode && tree_delegate.hasChildren
            text: ""

            TapHandler {
                onSingleTapped: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.selectionModel.setCurrentIndex(index, ItemSelectionModel.NoUpdate);
                    tree_delegate.treeView.toggleExpanded(tree_delegate.row);
                }
            }
        }

        Label {
            id: label
            x: padding + (tree_delegate.isTreeNode ? (tree_delegate.depth + 1) * tree_delegate.indentation : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - padding - x
            clip: true
            text: tree_delegate.display // model.display works but qmlls doesn't like it.
            font.pointSize: tree_delegate.is_current_item() ? 12 : 10

            // Animate font size changes
            Behavior on font.pointSize {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Context menu for tree items
        MenuWithKbd {
            id: contextMenu

            Action {
                text: qsTr("&Expand")
                enabled: tree_delegate.isTreeNode && tree_delegate.hasChildren && !tree_delegate.expanded
                onTriggered: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.expand(tree_delegate.row);
                }
            }

            Action {
                text: qsTr("C&ollapse")
                enabled: tree_delegate.isTreeNode && tree_delegate.hasChildren && tree_delegate.expanded
                onTriggered: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.collapse(tree_delegate.row);
                }
            }

            MenuSeparator {}

            Action {
                text: qsTr("&Copy Text")
                onTriggered: {}
                shortcut: "C"
            }

        }
    }

    // Tree View to display Notes with some Default Keybindings
    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // Signal to emit when the current item changes
        signal currentItemChanged(string statistics)

        // property int currentRow: -1

        selectionModel: ItemSelectionModel {
            onCurrentChanged: {
                // When current index changes, emit the signal with item statistics
                if (currentIndex.row >= 0) {
                    let stats = treeModel.getNoteBody(currentIndex.row, currentIndex.column);
                    treeView.currentItemChanged(stats);
                }
            }
        }

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}

        // Connect to the KeyEmitter when the component is created
        Component.onCompleted: {
            keyEmitter.setView(treeView);
        }

        // Add keyboard shortcuts
        Keys.onPressed: function (event) {
            // 'j' key to move down (like Down arrow)
            if (event.key === Qt.Key_J) {
                // Use the KeyEmitter to simulate a Down key press
                keyEmitter.emitDownKey();
                event.accepted = true;
            } else
            // 'k' key to move up (like Up arrow)
            if (event.key === Qt.Key_K) {
                keyEmitter.emitUpKey();
                event.accepted = true;
            } else
            // 'h' key to collapse/move left
            if (event.key === Qt.Key_H) {
                keyEmitter.emitLeftKey();
                event.accepted = true;
            } else
            // 'l' key to expand/move right
            if (event.key === Qt.Key_L) {
                keyEmitter.emitRightKey();
                event.accepted = true;
            }
        }
    }


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
