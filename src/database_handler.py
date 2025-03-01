
from __future__ import annotations
import sqlite3
from datetime import datetime
from typing import final


@final
class Note:
    def __init__(
        self,
        id: str,
        title: str,
        body: str,
        folder_id: str,
        parent: Note | Folder | None = None,
        created_at: datetime | None = None,
        updated_at: datetime | None = None,
    ):
        self.id = id
        self.title = title
        self.body = body
        self.folder_id = folder_id
        self.parent = parent
        self.children: list["Note"] = []
        # If no timestamps are provided, set them to the current time
        self.created_at = created_at if created_at else datetime.now()
        self.updated_at = updated_at if updated_at else datetime.now()


@final
class Folder:
    def __init__(
        self,
        id: str,
        title: str,
        parent: Folder | None,
        created_at: datetime | None = None,
        updated_at: datetime | None = None,
    ):
        self.id = id
        self.title = title
        self.children: list[Folder | Note] = []
        self.parent = parent
        # If no timestamps are provided, set them to the current time
        self.created_at = created_at if created_at else datetime.now()
        self.updated_at = updated_at if updated_at else datetime.now()


@final
class DatabaseHandler:
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection
        self.cursor = connection.cursor()

    def get_notes_recursive(
        self, parent_id: str | None = None, parent: Note | Folder | None = None
    ) -> list[Note]:
        """
        Recursively get notes in a nested structure

        Args:
            parent_id: ID of the parent note (None for top-level notes)
            parent: Parent Note or Folder object

        Returns:
            List of Note objects with their children
        """
        # Get notes with the specified parent_id
        if parent_id is None:
            _ = self.cursor.execute(
                "SELECT id, title, body, folder_id FROM notes WHERE parent_note_id IS NULL"
            )
        else:
            _ = self.cursor.execute(
                "SELECT id, title, body, folder_id FROM notes WHERE parent_note_id = ?",
                (parent_id,),
            )

        result: list[Note] = []
        for row in self.cursor.fetchall():  # pyright: ignore[reportAny]
            note_id: str
            title: str
            folder_id: str
            body: str
            note_id, title, body, folder_id = row

            # Create a Note object
            note = Note(
                id=note_id, title=title, body=body, folder_id=folder_id, parent=parent
            )

            # Check if this note has children
            _ = self.cursor.execute(
                "SELECT COUNT(*) FROM notes WHERE parent_note_id = ?", (note_id,)
            )
            has_children: bool = self.cursor.fetchone()[0] > 0

            if has_children:
                # Get children recursively and attach them to the note
                note.children = self.get_notes_recursive(note_id, note)
                result.append(note)
            else:
                result.append(note)

        return result

    def get_folders_with_notes(self) -> list[Folder]:
        """
        Get all folders with their notes

        Returns:
            List of Folder objects with their notes
        """
        # Get all folders
        _ = self.cursor.execute("SELECT id, name FROM folders")

        result: list[Folder] = []
        for row in self.cursor.fetchall():  # pyright: ignore[reportAny]
            folder_id: str
            title: str
            folder_id, title = row

            # Create a Folder object
            folder = Folder(id=folder_id, title=title, parent=None)

            # Get top-level notes in this folder
            folder.children = []
            _ = self.cursor.execute(
                "SELECT id, title, body  FROM notes WHERE folder_id = ? AND parent_note_id IS NULL",
                (folder_id,),
            )

            for note_row in self.cursor.fetchall():  # pyright: ignore[reportAny]
                note_id: str
                body: str
                note_id, title, body = note_row

                # Create a Note object
                note = Note(
                    id=note_id,
                    title=title,
                    body=body,
                    folder_id=folder_id,
                    parent=folder,
                )

                # Check if this note has children
                _ = self.cursor.execute(
                    "SELECT COUNT(*) FROM notes WHERE parent_note_id = ?", (note_id,)
                )
                has_children: bool = self.cursor.fetchone()[0] > 0

                if has_children:
                    # Get children recursively
                    note.children = self.get_notes_recursive(note_id, note)

                folder.children.append(note)

            result.append(folder)

        return result
