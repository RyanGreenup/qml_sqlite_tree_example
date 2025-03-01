import os
import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType, QQmlContext
from PySide6.QtWidgets import QApplication
from tree_model import TreeModel
from key_emitter import KeyEmitter
from init_db import create_sqlite_data, create_sqlite_database
import sqlite3



def main():
    app = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    engine = QQmlApplicationEngine()

    # Set up the database
    db_path = Path("./exemplar_data.sqlite")
    if os.path.exists(db_path):
        os.remove(db_path)

    # Create a persistent connection to the database
    conn = sqlite3.connect(db_path)
    create_sqlite_database(conn)
    create_sqlite_data(conn)


    # Create the model with database connection and expose it to QML
    tree_model = TreeModel(conn)
    engine.rootContext().setContextProperty("treeModel", tree_model)

    # Create and expose the key emitter
    key_emitter = KeyEmitter()
    engine.rootContext().setContextProperty("keyEmitter", key_emitter)

    qml_file = Path(__file__).parent / "qml" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
