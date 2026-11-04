// a line to type into
import QtQuick

Rectangle {
    id: field
    property alias text: input.text
    property string hint
    property string icon: "search"
    property bool secret: false                // what is typed shows as dots
    signal accepted()
    signal escaped()
    // a name to rename, as Windows and Nautilus offer it (ROADMAP 10L.02): the cursor in it, what is before the last
    // dot chosen (a file's name without its ending); `whole`, or no dot, or one that starts with it (.bashrc): all of it
    function focusName(whole) { input.forceActiveFocus(); const d = input.text.lastIndexOf("."); input.select(0, !whole && d > 0 ? d : input.text.length) }
    implicitWidth: 320; height: 40; radius: 12; color: Theme.card; border.width: 1; border.color: input.activeFocus ? Theme.gold : Theme.line
    Glyph { x: 12; name: field.icon; font.pixelSize: 16; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
    TextInput { id: input; x: 38; width: parent.width - 50; anchors.verticalCenter: parent.verticalCenter; color: Theme.cream; font.family: Theme.font; font.pixelSize: 14; clip: true; echoMode: field.secret ? TextInput.Password : TextInput.Normal
                selectByMouse: true; selectionColor: Theme.coffee; onAccepted: field.accepted()
                Keys.onEscapePressed: ev => { ev.accepted = true; field.escaped() } }
    Label { x: 38; text: field.hint; color: Theme.faint; visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter }
}
