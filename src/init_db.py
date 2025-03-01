import sqlite3


def create_sqlite_database(conn: sqlite3.Connection):

    conn.execute('''PRAGMA journal_mode('WAL');''')
    conn.execute('''
    -- Folders table
    CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );''')
    conn.execute('''
    -- Notes table
    CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT,
        folder_id TEXT,
        parent_note_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

        -- Foreign key to folders table
        FOREIGN KEY (folder_id)
        REFERENCES folders (id)
        ON DELETE CASCADE,

        -- Foreign key to parent note (self-referencing)
        FOREIGN KEY (parent_note_id)
        REFERENCES notes (id)
        ON DELETE CASCADE
    );
                 ''')

    conn.execute('''
    -- Index for faster lookups
    CREATE INDEX idx_notes_folder_id ON notes (folder_id);
                 ''')

    conn.execute('''
    CREATE INDEX idx_notes_parent_note_id ON notes (parent_note_id);
                 ''')
    conn.commit()

def create_sqlite_data(conn: sqlite3.Connection):
    """Create test data with nested notes structure"""
    cursor = conn.cursor()

    # Clear existing data
    cursor.execute("DELETE FROM notes")
    cursor.execute("DELETE FROM folders")

    # Create a folder
    cursor.execute("INSERT INTO folders (id, name) VALUES (1, 'Test Folder')")

    # Create parent notes
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (1, 'Parent1', 'Parent1 description', 1, NULL)
    """)
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (2, 'Parent2', 'Parent2 description', 1, NULL)
    """)

    # Create child notes under Parent1
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (3, 'Child1', 'Child1 description', 1, 1)
    """)
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (4, 'Child2', 'Child2 description', 1, 1)
    """)

    # Create grandchild note under Child2
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (5, 'Grandchild1', 'Grandchild1 description', 1, 4)
    """)

    conn.commit()


