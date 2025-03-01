import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

// Tree View to display Notes with some Default Keybindings
TreeView {
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

    delegate: Item {
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
}
