pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

Menu {
    id: my_menu
    delegate: MenuItem {
        id: control

        contentItem: Item {
            anchors.centerIn: parent

            Text {

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
                text: transformString(control.text)
                // text: "My <u>S</u>tring"
                anchors.left: parent.left
                color: Universal.foreground
            }

            Text {
                function get_shortcut_text() {
                    const s = control.action.shortcut
                    if (typeof s  !== "undefined") {
                        return s
                    } else {
                        return ""
                    }

                }
                text: get_shortcut_text()
                anchors.right: parent.right
                color: Universal.foreground
            }
        }
    }
}
