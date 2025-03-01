from PySide6.QtCore import QObject, Slot, Qt
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication
import functools

def key_emitter(key):
    """Decorator to create key event emitter methods"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(self, *args, **kwargs):
            # Call the original function first (for any logging, etc.)
            func(self, *args, **kwargs)

            if self.view:
                # Create key press event
                key_press = QKeyEvent(
                    QKeyEvent.Type.KeyPress, key, Qt.KeyboardModifier.NoModifier
                )
                # Create key release event
                key_release = QKeyEvent(
                    QKeyEvent.Type.KeyRelease, key, Qt.KeyboardModifier.NoModifier
                )

                # Send events to the view
                QApplication.sendEvent(self.view, key_press)
                QApplication.sendEvent(self.view, key_release)
        return wrapper
    return decorator

class KeyEmitter(QObject):
    """Helper class to emit key events directly to the TreeView"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.view = None

    @Slot("QVariant")
    def setView(self, view):
        """Set the TreeView object that will receive key events"""
        self.view = view

    @Slot()
    @key_emitter(Qt.Key.Key_Down)
    def emitDownKey(self):
        """Emit a Down arrow key press to the TreeView"""
        print("Down")

    @Slot()
    @key_emitter(Qt.Key.Key_Up)
    def emitUpKey(self):
        """Emit an Up arrow key press to the TreeView"""
        pass

    @Slot()
    @key_emitter(Qt.Key.Key_Left)
    def emitLeftKey(self):
        """Emit a Left arrow key press to the TreeView"""
        pass

    @Slot()
    @key_emitter(Qt.Key.Key_Right)
    def emitRightKey(self):
        """Emit a Right arrow key press to the TreeView"""
        pass
