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

    // Property to store the parent index for new notes
    property var currentParentIndex: null

    // Property to store expanded item IDs
    property var expanded_items: []
    property var current_item_before_refresh: ""

    // Helper functions for index/row conversion
    function get_row_from_index(index) {
        // Return the row from a model index
        if (index && index.valid) {
            return index.row;
        }
        return -1;
    }

    function get_index_from_row(row, column = 0) {
        // Create and return a model index for the given row and column
        return treeView.index(row, column);
    }

    function focus_note_from_id(id) {
        let index = treeModel.get_index_by_id(id);

        // Expand up to the previous current Item
        treeView.expandToIndex(index);
        // Focus that item again
        forceLayout()
        // Position at that item
        positionViewAtRow(rowAtIndex(index), Qt.AlignVCenter)

        // Set the current Item
        // Set the current item using the selection model of the treeView AI!
    }

    function get_indexes_from_ids(id_list) {
        var index_list = [];
        var row_list = [];
        for (let i = 0; i < id_list.length; i++) {
            let id = id_list[i];
            console.log("Considering expand of: " + id);
            let index = treeModel.get_index_by_id(id);
            if (index && index.valid) {
                try {
                    treeView.expandToIndex(index);
                } catch (e) {
                    console.error("Error expanding index: " + e);
                }
            }
        }
    }

    selectionModel: ItemSelectionModel {
        onCurrentChanged: function (current, previous) {
            // current: QModelIndex
            if (current.valid) {
                // Get details from the model and emit the signal
                let details = treeModel.getItemDetails(current);
                treeView.currentItemChanged(details);
            }
        }
    }

    // Connect to our Python model
    model: treeModel

    // Track expanded and collapsed items
    onExpanded: function (row, depth) {
        // NOTE depth always 1 according to docs
        // Store expanded items to potentially restore state later
        let index = get_index_from_row(row, 0);
        console.log("----------------_> " + index);
        let id = treeModel.get_id(index);
        let title = treeModel.get_title(index);
        let child_id = treeModel.get_first_child_id(index)
        treeView.expanded_items.push(child_id);
        console.log("Expanded " + id + "( " + title + ") all: " + treeView.expanded_items);
    }

    onCollapsed: function (row) {
        let index = get_index_from_row(row);
        let id = treeModel.get_id(index);
        // Remove collapsed items from the expanded_items array
        const js_index = expanded_items.indexOf(id);
        if (js_index !== -1) {
            expanded_items.splice(js_index, 1);
        }
    }

    // Connect to the KeyEmitter when the component is created
    Component.onCompleted: {
        keyEmitter.setView(treeView);
    }

    // New Note Dialog
    NewNoteDialog {
        id: newNoteDialog

        onNoteCreated: function (title, body) {
            if (treeView.currentParentIndex) {
                treeModel.createNoteWithDetails(treeView.currentParentIndex, title, body);
            }
        }
    }

    // Edit Title Dialog
    EditTitleDialog {
        id: editTitleDialog

        onTitleEdited: function(newTitle) {
            // Get the current index
            let index = treeView.selectionModel.currentIndex;
            if (index.valid) {
                // Update the title in the model
                treeModel.update_title(index, newTitle);
            }
        }
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
        required property string decoration

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

        // Item type icon
        Image {
            id: itemIcon
            x: padding + (tree_delegate.isTreeNode ? (tree_delegate.depth + 1) * tree_delegate.indentation : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: {
                // Use decoration role to determine icon
                if (tree_delegate.decoration === "folder") {
                    return "qrc:///qt-project.org/styles/commonstyle/images/standardbutton-open-16.png";
                } else {
                    return "qrc:///qt-project.org/styles/commonstyle/images/file-16.png";
                }
            }
            opacity: tree_delegate.is_current_item() ? 1.0 : 0.8
        }

        Label {
            id: label
            x: itemIcon.x + itemIcon.width + 5 // Position after the icon with some spacing
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
                text: qsTr("Create &New Note")
                enabled: true
                onTriggered: {
                    // Get the current index
                    let index = tree_delegate.treeView.selectionModel.currentIndex;

                    // Store the current index for later use
                    treeView.currentParentIndex = index;

                    // Show the dialog
                    newNoteDialog.open();
                }
                shortcut: "N"
            }

            Action {
                text: qsTr("&Edit Title")
                enabled: true
                onTriggered: {
                    let index = tree_delegate.treeView.selectionModel.currentIndex

                    tree_delegate.treeView.selectionModel.setCurrentIndex(index, ItemSelectionModel.ClearAndSelect);

                    if (index.valid) {
                        // Get the current title
                        let currentTitle = treeModel.get_title(index);

                        // Set the current title in the dialog
                        editTitleDialog.currentTitle = currentTitle;

                        // Show the dialog
                        editTitleDialog.open();
                    }
                }
                shortcut: "E"
            }

            Action {
                text: qsTr("&Copy Text")
                onTriggered: {}
                shortcut: "C"
            }

            MenuSeparator {}

            Action {
                text: qsTr("&Refresh Tree")
                onTriggered: {
                    // Store current expanded items before refresh
                    let current_expanded = [...treeView.expanded_items];
                    let current_item_index = tree_delegate.treeView.selectionModel.currentIndex;
                    let current_item_id = treeModel.get_id(current_item_index)

                    // Refresh the tree
                    treeModel.refreshTree();
                    treeView.expanded_items = [];

                    // Unfold up to any unfolded items (so one short #TODO [maybe store the first child?])
                    get_indexes_from_ids(current_expanded);

                    // Restore the last item
                    focus_note_from_id(current_item_id);


                    // Use a timer to ensure the model is fully updated before restoring
                    // Timer {
                    //     interval: 100,
                    //     running: true,
                    //     onTriggered: function() {
                    //         // Restore expanded state
                    //         get_indexes_from_ids(current_expanded);
                    //     }
                    // }
                }
                shortcut: "R"
            }
        }
    }
}
