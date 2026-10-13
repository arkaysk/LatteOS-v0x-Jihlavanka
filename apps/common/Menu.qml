// A menu at the pointer: rows with an icon, a tick, a hint or a further menu, as the right button gives on
// Windows. It lies over everything in the window it is in, and a press anywhere else closes it.
//   Menu { id: menu }      menu.open(x, y, [{ text, icon, hint, checked, danger, enabled, bold, run, more: […] }, { line: true }])
import QtQuick

Item {
    id: menu
    anchors.fill: parent
    visible: false
    z: 1000
    property var rows: []
    property var further: []                   // the rows of the menu a row opened
    property int furtherAt: -1
    property real px: 0
    property real py: 0
    function open(x, y, list) { rows = list; further = []; furtherAt = -1; px = x; py = y; visible = true }
    function close() { visible = false; rows = []; further = [] }

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: menu.close(); onWheel: (w) => w.accepted = true }

    component Sheet: Rectangle {
        id: sheet
        property var list: []
        property bool lead: true               // the first menu, which can open the further one
        width: 268; height: col.implicitHeight + 12; radius: 12
        color: Theme.card; border.width: 1; border.color: Theme.line
        Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 13; z: -1; color: "transparent"; border.width: 6; border.color: Qt.rgba(0, 0, 0, 0.12) }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        Column { id: col; x: 6; y: 6; width: parent.width - 12
            Repeater { model: sheet.list
                Item { id: row; required property var modelData; required property int index
                    readonly property bool usable: modelData.enabled !== false
                    width: col.width; height: modelData.line ? 9 : 32
                    Rectangle { visible: row.modelData.line === true; x: 8; width: parent.width - 16; height: 1; color: Theme.line; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle { visible: !row.modelData.line; anchors.fill: parent; radius: 7
                                color: (hit.containsMouse && row.usable) || (sheet.lead && menu.furtherAt === row.index) ? Theme.raised : "transparent" }
                    Glyph { visible: !row.modelData.line; x: 10; name: row.modelData.checked ? "check" : (row.modelData.icon || ""); font.pixelSize: 16
                            color: row.modelData.danger ? Theme.red : (row.usable ? Theme.cream : Theme.faint); anchors.verticalCenter: parent.verticalCenter }
                    Label { visible: !row.modelData.line; x: 38; width: parent.width - 38 - tail.width - 14; text: row.modelData.text || ""
                            font.weight: row.modelData.bold ? 700 : 500; color: row.modelData.danger ? Theme.red : (row.usable ? Theme.cream : Theme.faint); anchors.verticalCenter: parent.verticalCenter }
                    Row { id: tail; visible: !row.modelData.line; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                          Label { text: row.modelData.hint || ""; color: Theme.faint; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                          Glyph { visible: row.modelData.more !== undefined; name: "chevron-right"; font.pixelSize: 15; color: Theme.dim } }
                    MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; enabled: !row.modelData.line
                        onEntered: if (sheet.lead) { if (row.modelData.more && row.usable) { menu.further = row.modelData.more; menu.furtherAt = row.index; second.rowY = row.y } else { menu.further = []; menu.furtherAt = -1 } }
                        onClicked: { if (!row.usable || row.modelData.more) return
                                     const run = row.modelData.run; if (!row.modelData.keep) menu.close(); if (run) run() } } } } }
    }
    // kept on the screen: it opens to the left or upwards where the edge is near
    Sheet { id: first; list: menu.rows
            x: Math.max(6, Math.min(menu.px, menu.width - width - 6)); y: Math.max(6, Math.min(menu.py, menu.height - height - 6)) }
    Sheet { id: second; list: menu.further; lead: false; visible: menu.further.length > 0
            property real rowY: 0
            x: first.x + first.width + width + 2 <= menu.width ? first.x + first.width + 2 : first.x - width - 2
            y: Math.max(6, Math.min(first.y + rowY, menu.height - height - 6)) }
}
