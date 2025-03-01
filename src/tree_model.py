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
from .database_handler import Note, Folder, DatabaseHandler


@final
class TreeModel(QAbstractItemModel):
    def __init__(
        self, db_connection: sqlite3.Connection, parent: QObject | None = None
    ):
        super().__init__(parent)

        # Create database handler
        self.db_handler = DatabaseHandler(db_connection)

        # Create a dummy root item
        self.root_item = Folder(id="0", title="Root", parent=None)

        # Get folders with notes and set them as children of root
        self.tree_data: list[Folder] = self.db_handler.get_folders_with_notes()

        # Connect root folders to the root item
        for folder in self.tree_data:
            folder.parent = self.root_item

        # Set the folders as children of the root item
        self.root_item.children = self.tree_data  # pyright: ignore [reportAttributeAccessIssue]

    @override
    def columnCount(
        self, parent: QModelIndex | QPersistentModelIndex = QModelIndex() # pyright: ignore [reportCallInDefaultInitializer]
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

    def _get_item(self, index: QModelIndex | QPersistentModelIndex) -> Folder | Note | None:
        if not index.isValid():
            return None

        untyped_item = index.internalPointer()  # pyright: ignore[reportAny]
        if untyped_item is None:
            print("Error: index.internalPointer() returned None", file=sys.stderr)
            return None

        if not (isinstance(untyped_item, Folder) or isinstance(untyped_item, Note)):
            print(f"Error, Item in Tree has wrong type: {type(untyped_item)}, this is a bug!", file=sys.stderr)
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

        if (
            role != Qt.ItemDataRole.DisplayRole
            and role != Qt.ItemDataRole.UserRole
            and role != Qt.ItemDataRole.EditRole
        ):
            return None

        column: int = index.column()
        row: int = index.row()
        _ = row
        item = self._get_item(index)

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
        role: int = int(Qt.ItemDataRole.DisplayRole),  # pyright: ignore [reportCallInDefaultInitializer]
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
        parent: QModelIndex | QPersistentModelIndex = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
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
        print("-------")
        print("child items are: ")
        print([item.title for item in child_items])
        print("-------")
        # Get the Specific child item
        child_item = child_items[row]
        # Create an index from that child item
        child_index = self.createIndex(row, column, child_item)

        # Return that index
        return child_index

    @override
    def parent(self, index: QModelIndex | QPersistentModelIndex):  # pyright: ignore [reportIncompatibleMethodOverride]
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
            row = parent_parent.children.index(parent_item)  # pyright: ignore [reportArgumentType]
        else:
            # This should not happen with our structure, but just in case
            row = 0

        return self.createIndex(row, 0, parent_item)

    @override
    def rowCount(self,
                 parent: QModelIndex | QPersistentModelIndex = QModelIndex()  # pyright: ignore [reportCallInDefaultInitializer]
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


