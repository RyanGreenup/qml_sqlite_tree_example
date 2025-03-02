import sys
import sqlite3
from PySide6.QtCore import (
    QAbstractItemModel,
    QByteArray,
    QModelIndex,
    QObject,
    QPersistentModelIndex,
    Qt,
    Slot,
)
from typing import final, override
from src.database_handler import Note, Folder, DatabaseHandler


@final
class TreeModel(QAbstractItemModel):
    def __init__(
        self, db_connection: sqlite3.Connection, parent: QObject | None = None
    ):
        super().__init__(parent)

        # Create database handler
        self.db_handler = DatabaseHandler(db_connection)

        # Create a dummy root item to set as invisible first item
        self.root_item = Folder(id="0", title="Root", parent=None)

        # Create a dictionary to store id -> index mapping
        self.id_to_index_map = {}

        self._build_tree()

    @override
    def columnCount(
        self,
        parent: (
            QModelIndex | QPersistentModelIndex
        ) = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        fixed_columns = 1
        if parent.isValid():
            # Assuming the parent has a .columnCount() method we could use
            # We may want to match
            # parent_item = self._get_item(parent)
            # return parent_item.columnCount()
            return fixed_columns

        # Change this if you want more columns
        return fixed_columns

    def _get_item(
        self, index: QModelIndex | QPersistentModelIndex
    ) -> Folder | Note | None:
        if not index.isValid():
            return None

        untyped_item = index.internalPointer()  # pyright: ignore[reportAny]
        if untyped_item is None:
            print("Error: index.internalPointer() returned None", file=sys.stderr)
            return None

        if not (isinstance(untyped_item, Folder) or isinstance(untyped_item, Note)):
            print(
                f"Error, Item in Tree has wrong type: {type(untyped_item)}, this is a bug!",
                file=sys.stderr,
            )
            return None

        item: Folder | Note = untyped_item
        return item

    @override
    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = int(
            Qt.ItemDataRole.DisplayRole
        ),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        if not index.isValid():
            return None

        if role not in [
            Qt.ItemDataRole.DisplayRole,
            Qt.ItemDataRole.UserRole,
            Qt.ItemDataRole.EditRole,
            Qt.ItemDataRole.DecorationRole,
        ]:
            return None

        column: int = index.column()
        row: int = index.row()
        _ = row
        item = self._get_item(index)

        # Used to set an icon
        if role == Qt.ItemDataRole.DecorationRole and column == 0:
            return "folder" if isinstance(item, Folder) else "note"

        if item is None:
            return None
        else:
            match column:
                case 0:
                    return item.title
                case 1:
                    return item.id
                case _:
                    return None

    @override
    def flags(self, index: QModelIndex | QPersistentModelIndex):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags

        return (
            Qt.ItemFlag.ItemIsEnabled
            | Qt.ItemFlag.ItemIsSelectable
            | Qt.ItemFlag.ItemIsEditable
        )

    # Section is the column
    @override
    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = int(
            Qt.ItemDataRole.DisplayRole
        ),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        if (
            orientation == Qt.Orientation.Horizontal
            and role == Qt.ItemDataRole.DisplayRole
        ):
            match section:
                case 0:
                    return "Title"
                case _:
                    return None

        return None

    @override
    def index(
        self,
        row: int,
        column: int,
        parent: (
            QModelIndex | QPersistentModelIndex
        ) = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
    ) -> QModelIndex:
        if not self.hasIndex(row, column, parent):
            return QModelIndex()

        # Return the Root Item or the parent of the current item
        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = self._get_item(parent)

        # Get the children of the parent
        child_items = parent_item.children
        # Get the Specific child item
        child_item = child_items[row]
        # Create an index from that child item
        child_index = self.createIndex(row, column, child_item)

        # Return that index
        return child_index

    @override
    def parent(
        self, index: QModelIndex | QPersistentModelIndex
    ):  # pyright: ignore [reportIncompatibleMethodOverride]
        # Note the ignore is likely a stubs error, docs suggests this is correct
        # https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html#PySide6.QtCore.QAbstractItemModel.parent
        if not index.isValid():
            return QModelIndex()

        child_item: Folder | Note = self._get_item(index)
        parent_item = child_item.parent

        if parent_item is None or parent_item == self.root_item:
            return QModelIndex()

        # Find the row of the parent in its parent's children
        if parent_item.parent is not None:
            parent_parent = parent_item.parent
            row = parent_parent.children.index(
                parent_item
            )  # pyright: ignore [reportArgumentType]
        else:
            # This should not happen with our structure, but just in case
            row = 0

        return self.createIndex(row, 0, parent_item)

    @override
    def rowCount(
        self,
        parent: (
            QModelIndex | QPersistentModelIndex
        ) = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        if parent.column() > 0:
            return 0

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = self._get_item(parent)

        return len(parent_item.children)

    @override
    def roleNames(self):
        roles = {
            Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
            Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
            Qt.ItemDataRole.EditRole: QByteArray(b"edit"),
            Qt.ItemDataRole.DecorationRole: QByteArray(b"decoration"),
        }
        r: dict[int, QByteArray] = roles  # pyright: ignore [reportAssignmentType]
        return r

    @Slot(QModelIndex, result=str)
    def getItemDetails(self, index: QModelIndex) -> str:
        """Get details for the selected item (note body or folder info)"""
        if not index.isValid():
            return "No item selected"

        item = self._get_item(index)
        if item is None:
            return "Invalid item"

        if isinstance(item, Note):
            return item.body
        elif isinstance(item, Folder):
            # For folders, return some basic info
            child_count = len(item.children)
            return f"Folder: {item.title}\nContains {child_count} items"
        else:
            return "Unknown item type"

    @Slot(QModelIndex)
    def createNewNote(self, parent_index: QModelIndex) -> None:
        """Create a new note under the specified parent item"""
        if not parent_index.isValid():
            return

        parent_item = self._get_item(parent_index)
        if parent_item is None:
            return

        # The actual note creation will be handled by createNoteWithDetails
        # This method now just signals that we want to create a note under this parent
        # The UI will show a dialog and then call createNoteWithDetails
        pass

    @Slot(QModelIndex, str, str)
    def createNoteWithDetails(
        self, parent_index: QModelIndex, title: str, body: str
    ) -> None:
        """Create a new note with the specified title and body under the parent item"""
        if not parent_index.isValid():
            return

        parent_item = self._get_item(parent_index)
        if parent_item is None:
            return

        # Get the position where the new note will be inserted
        insert_position = len(parent_item.children)

        # Begin inserting rows
        self.beginInsertRows(parent_index, insert_position, insert_position)

        # Create the new note in the database and get the Note object
        new_note = self.db_handler.create_note(
            title=title, body=body, parent=parent_item
        )

        # End inserting rows
        self.endInsertRows()

        # Add the new note to the map
        new_index = self.createIndex(insert_position, 0, new_note)
        self.id_to_index_map[new_note.id] = new_index

    def _build_tree(self) -> None:
        # Reload the data from the database
        self.tree_data = self.db_handler.get_folders_with_notes()

        # Connect root folders to the root item
        for folder in self.tree_data:
            folder.parent = self.root_item

        # Set the folders as children of the root item
        self.root_item.children = (
            self.tree_data
        )  # pyright: ignore [reportAttributeAccessIssue]

        # Clear the existing map and rebuild it
        self.id_to_index_map = {}
        self._build_id_index_map()

    def _build_id_index_map(self) -> None:
        """Build a mapping of item IDs to their QModelIndex"""
        # Start with an empty map
        self.id_to_index_map = {}

        # Process the root item's children (which are the top-level folders)
        for row, item in enumerate(self.root_item.children):
            # Create the index for this item
            index = self.createIndex(row, 0, item)
            # Add to the map
            self.id_to_index_map[item.id] = index
            # Recursively process this item's children
            self._map_children_indices(item, index)

    def _map_children_indices(self, parent_item: Folder | Note, parent_index: QModelIndex) -> None:
        """Recursively map all children of an item to their indices"""
        for row, child in enumerate(parent_item.children):
            # Create the index for this child
            child_index = self.createIndex(row, 0, child)
            # Add to the map
            self.id_to_index_map[child.id] = child_index
            # If this child has children, process them too
            if hasattr(child, 'children') and child.children:
                self._map_children_indices(child, child_index)


    @Slot()
    def refreshTree(self) -> None:
        """Refresh the tree by reloading all data from the database"""
        # Notify the view that we're about to reset the model
        self.beginResetModel()

        self._build_tree()
        # The map is now rebuilt in _build_tree()

        # Notify the view that the model has been reset
        self.endResetModel()

    @Slot(str, result=QModelIndex)
    def get_index_by_id(self, item_id: str) -> QModelIndex:
        """Get the QModelIndex for an item with the given ID"""
        if item_id in self.id_to_index_map:
            return self.id_to_index_map[item_id]
        return QModelIndex()


    @Slot(QModelIndex, result=str)
    def get_id(self, index: QModelIndex) -> str:
        if (item := self._get_item(index)):
            return item.id
        else:
            return ""


    @Slot(QModelIndex, result=str)
    def get_title(self, index: QModelIndex) -> str:
        if (item := self._get_item(index)):
            return item.title
        else:
            return ""

    @Slot(QModelIndex, result=str)
    def get_first_child_id(self, index: QModelIndex) -> str:
        """
        Used for the expandToIndex function on refresh
        """
        if (item := self._get_item(index)):
            return item.children[0].id
        else:
            return ""

    @Slot(QModelIndex, str, result=bool)
    def update_title(self, index: QModelIndex, new_title: str) -> bool:
        """
        Update the title of a Note or Folder

        Args:
            index: The QModelIndex of the item to update
            new_title: The new title to set

        Returns:
            bool: True if the update was successful, False otherwise
        """
        if not index.isValid() or not new_title.strip():
            return False

        item = self._get_item(index)
        if item is None:
            return False

        try:
            # Update the title in the database and the object
            self.db_handler.update_title(item, new_title)

            # Notify the view that the data has changed
            self.dataChanged.emit(index, index, [Qt.ItemDataRole.DisplayRole])

            # The ID hasn't changed, so we don't need to update the map

            return True
        except Exception as e:
            print(f"Error updating title: {e}", file=sys.stderr)
            return False

