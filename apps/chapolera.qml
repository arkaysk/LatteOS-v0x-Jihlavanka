//@ pragma AppId latteos-chapolera
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell
    readonly property var words: (Quickshell.env("LATTE_APP_ARGS") || "").split("\n").filter(w => w !== "")
    readonly property string folder: words[0] || ""
    readonly property string folderName: {
        const parts = folder.split("/").filter(part => part !== "")
        return parts.length ? parts[parts.length - 1] : (folder ? "/" : I18n.tr("No folder selected"))
    }
    readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config"))
                                           + "/latteos/chapolera.json"
    property var aiProviders: []
    property bool modelsLoading: true
    property string modelError: ""
    property string selectedProviderId: ""
    property string selectedModelId: ""
    property string defaultProviderId: ""
    property string defaultModelId: ""
    property var result: null
    property bool scanning: false
    property bool pileSettled: false
    property string scanError: ""
    property string settingsError: ""
    property string memoryError: ""
    property string sortingInstruction: ""
    property bool settingsReady: false
    property bool automaticPreviews: true
    property int manualPreviewLimit: 24
    property int automaticPreviewLimit: 8
    property bool memoryReady: false
    property int pageOffset: 0
    property bool pendingScan: false
    readonly property int previewLimit: automaticPreviews ? automaticPreviewLimit : manualPreviewLimit
    readonly property var selectedProvider: aiProviders.find(provider => provider.id === selectedProviderId) || null
    readonly property var selectedModel: selectedProvider
        ? selectedProvider.models.find(model => model.id === selectedModelId) || null
        : null
    readonly property var counts: result ? result.counts : ({ total: 0, photos: 0, videos: 0, audio: 0, other: 0, subfolders: 0 })
    readonly property var beforeRows: [
        { name: "Total files", value: String(counts.total), icon: "file" },
        { name: "Photos", value: String(counts.photos), icon: "photo" },
        { name: "Videos", value: String(counts.videos), icon: "video" },
        { name: "Audio", value: String(counts.audio), icon: "music" },
        { name: "Subfolders", value: String(counts.subfolders), icon: "folder" }
    ]
    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function validPreviewLimit(value) {
        return Number.isInteger(value) && value >= 8 && value <= 96 && (value - 8) % 4 === 0
    }

    function acceptSettings(settings) {
        if (!settings || typeof settings.automatic !== "boolean" || !validPreviewLimit(settings.preview_limit)) {
            settingsError = I18n.tr("Chapolera settings are invalid.")
            if (!settingsReady) {
                automaticPreviews = true
                manualPreviewLimit = 24
                automaticPreviewLimit = 8
                memoryReady = true
                settingsReady = true
                scan()
            }
            return
        }
        settingsError = ""
        const modeChanged = automaticPreviews !== settings.automatic
        const oldLimit = previewLimit
        automaticPreviews = settings.automatic
        manualPreviewLimit = settings.preview_limit
        settingsReady = true
        if (automaticPreviews) {
            if (modeChanged) memoryReady = false
            if (!memoryReady) requestMemory()
        } else {
            memoryReady = true
            memoryError = ""
            if (oldLimit !== previewLimit && pageOffset > 0)
                pageOffset = Math.floor(pageOffset / previewLimit) * previewLimit
            if (oldLimit !== previewLimit || result === null) scan()
        }
    }

    function loadSettings() {
        settingsReader.buf = ""
        settingsReader.command = ["latte-chapolera", "settings"]
        settingsReader.running = true
    }

    function requestMemory() {
        if (memoryReader.running) return
        memoryReader.buf = ""
        memoryReader.command = ["latte-chapolera", "memory"]
        memoryReader.running = true
    }

    function acceptMemory(bytes, limit) {
        const oldLimit = previewLimit
        if (!Number.isSafeInteger(bytes) || bytes < 0 || ![8, 12, 24, 48].includes(limit)) {
            memoryError = I18n.tr("Available memory could not be measured; using the smallest preview count.")
            automaticPreviewLimit = 8
        } else {
            memoryError = ""
            automaticPreviewLimit = limit
        }
        memoryReady = true
        if (oldLimit !== previewLimit && pageOffset > 0)
            pageOffset = Math.floor(pageOffset / previewLimit) * previewLimit
        if (oldLimit !== previewLimit || result === null) scan()
    }

    function failMemoryRead() {
        const oldLimit = previewLimit
        const wasReady = memoryReady
        memoryError = I18n.tr("Available memory could not be measured; using the smallest preview count.")
        automaticPreviewLimit = 8
        memoryReady = true
        if (oldLimit !== previewLimit && pageOffset > 0)
            pageOffset = Math.floor(pageOffset / previewLimit) * previewLimit
        if (!wasReady || oldLimit !== previewLimit || result === null) scan()
    }

    function scan() {
        if (!folder || !settingsReady || (automaticPreviews && !memoryReady)) return
        if (scanner.running) {
            pendingScan = true
            return
        }
        scanning = true
        pileSettled = false
        scanError = ""
        result = null
        scanner.buf = ""
        scanner.command = ["latte-chapolera", "scan", folder, String(previewLimit), String(pageOffset)]
        scanner.running = true
    }

    function openSettings() {
        settingsWindow.running = true
    }

    function showModelMenu(button) {
        const point = button.mapToItem(menuOverlay, 0, button.height)
        let rows
        if (modelsLoading) {
            rows = [{ text: I18n.tr("Loading LensAI models…"), icon: "sparkles", enabled: false }]
        } else if (modelError !== "") {
            rows = [{ text: modelError, icon: "alert-triangle", enabled: false }]
        } else if (aiProviders.length === 0) {
            rows = [{ text: I18n.tr("No AI providers are available in LensAI."), icon: "sparkles", enabled: false }]
        } else {
            rows = aiProviders.map(provider => ({
                text: provider.name,
                icon: "sparkles",
                hint: provider.local ? I18n.tr("On this computer") : I18n.tr("Cloud"),
                more: provider.models.map(model => ({
                    text: model.name,
                    hint: provider.id === defaultProviderId && model.id === defaultModelId
                          ? I18n.tr("LensAI default") : "",
                    checked: provider.id === selectedProviderId && model.id === selectedModelId,
                    run: () => shell.chooseModel(provider.id, model.id)
                }))
            }))
            rows.push({ line: true })
            rows.push({
                text: I18n.tr("Open model selection in LensAI"),
                icon: "sparkles",
                run: () => Quickshell.execDetached(["latte-app", "aicenter", "models"])
            })
        }
        modelMenu.open(point.x, point.y, rows)
    }

    function chooseModel(providerId, modelId) {
        selectedProviderId = providerId
        selectedModelId = modelId
    }

    function loadModels() {
        modelReader.buf = ""
        modelReader.running = true
    }

    Process {
        id: settingsReader
        property string buf: ""
        stdout: StdioCollector { onStreamFinished: settingsReader.buf = this.text }
        onExited: code => {
            if (code !== 0) {
                shell.settingsError = I18n.tr("Could not load Chapolera settings.")
                if (!shell.settingsReady) {
                    shell.settingsReady = true
                    shell.automaticPreviews = true
                    shell.manualPreviewLimit = 24
                    shell.automaticPreviewLimit = 8
                    shell.memoryReady = true
                    shell.scan()
                }
                return
            }
            try {
                shell.acceptSettings(JSON.parse(buf))
                settingsFile.reload()
            } catch (error) {
                shell.settingsError = I18n.tr("Chapolera settings are invalid.")
                if (!shell.settingsReady) {
                    shell.settingsReady = true
                    shell.memoryReady = true
                    shell.scan()
                }
            }
        }
    }

    Process {
        id: modelReader
        property string buf: ""
        command: ["latte-ai", "providers"]
        stdout: StdioCollector { onStreamFinished: modelReader.buf = this.text }
        onExited: code => {
            shell.modelsLoading = false
            if (code !== 0) {
                shell.modelError = I18n.tr("Could not load AI providers from LensAI.")
                return
            }
            try {
                const parsed = JSON.parse(buf)
                if (!Array.isArray(parsed)) throw new Error("LensAI providers are not a list")
                const valid = parsed.filter(provider => provider && typeof provider.id === "string"
                    && typeof provider.name === "string" && Array.isArray(provider.models))
                    .map(provider => ({
                        id: provider.id,
                        name: provider.name,
                        local: provider.local === true,
                        models: provider.models.filter(model => model && typeof model.id === "string"
                            && typeof model.name === "string")
                    }))
                    .filter(provider => provider.models.length > 0)
                shell.aiProviders = valid
                shell.modelError = ""
                if (valid.length === 0) return
                shell.defaultProviderId = valid[0].id
                shell.defaultModelId = valid[0].models[0].id
                const selected = valid.find(provider => provider.id === shell.selectedProviderId
                    && provider.models.some(model => model.id === shell.selectedModelId))
                const initial = selected || valid[0]
                shell.selectedProviderId = initial.id
                shell.selectedModelId = selected ? shell.selectedModelId : initial.models[0].id
            } catch (error) {
                shell.modelError = I18n.tr("LensAI returned an invalid provider list.")
            }
        }
    }

    Process {
        id: memoryReader
        property string buf: ""
        stdout: StdioCollector { onStreamFinished: memoryReader.buf = this.text }
        onExited: code => {
            if (code !== 0) {
                shell.failMemoryRead()
                return
            }
            try {
                const parsed = JSON.parse(buf)
                shell.acceptMemory(parsed.available_bytes, parsed.preview_limit)
            } catch (error) {
                shell.failMemoryRead()
            }
        }
    }

    Process {
        id: settingsWindow
        command: ["latte-chapolera-settings"]
        onExited: code => {
            if (code !== 0) {
                shell.settingsError = I18n.tr("Chapolera settings could not be opened.")
                return
            }
            shell.loadSettings()
        }
    }

    FileView {
        id: settingsFile
        path: shell.settingsPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (!shell.settingsReady) return
            try {
                shell.acceptSettings(JSON.parse(text()))
            } catch (error) {
                shell.settingsError = I18n.tr("Chapolera settings are invalid.")
            }
        }
    }

    Timer {
        interval: 10000
        running: shell.settingsReady && shell.automaticPreviews
        repeat: true
        onTriggered: shell.requestMemory()
    }

    Component.onCompleted: Qt.callLater(() => { shell.loadSettings(); shell.loadModels() })

    Process {
        id: scanner
        property string buf: ""
        stdout: StdioCollector { onStreamFinished: scanner.buf = this.text }
        onExited: code => {
            shell.scanning = false
            if (code !== 0) {
                shell.scanError = I18n.tr("Could not read this folder (exit code {code}).", { code })
            } else {
                try {
                    const parsed = JSON.parse(buf)
                    if (!parsed || !parsed.counts || !Array.isArray(parsed.files)
                            || !Number.isInteger(parsed.start) || typeof parsed.has_more !== "boolean")
                        throw new Error("Missing scan fields")
                    shell.result = parsed
                } catch (error) {
                    shell.scanError = I18n.tr("Folder scan returned invalid data.")
                }
            }
            if (shell.pendingScan) {
                shell.pendingScan = false
                Qt.callLater(shell.scan)
            }
        }
    }

    Timer {
        interval: 90
        running: shell.result !== null
        onTriggered: shell.pileSettled = true
    }

    AppWindow {
        title: "Chapolera"
        heading: I18n.tr("Sorting with:")
        implicitWidth: 1240
        implicitHeight: 780
        sideWidth: 260
        tools: [
            Pill {
                id: modelPicker
                icon: "chevron-down"
                text: shell.modelsLoading
                      ? I18n.tr("Loading models…")
                      : shell.selectedProvider && shell.selectedModel
                        ? shell.selectedProvider.name + " · " + shell.selectedModel.name
                        : I18n.tr("Model unavailable")
                busy: shell.modelsLoading
                onPressed: shell.showModelMenu(modelPicker)
            },
            Pill {
                icon: "settings"
                text: I18n.tr("Settings")
                onPressed: shell.openSettings()
            }
        ]
        side: [
            Column {
                x: 14
                y: 14
                width: 232
                spacing: 5

                Row {
                    x: 6
                    spacing: 10
                    height: 40
                    Glyph { name: "sparkles"; font.pixelSize: 24; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Chapolera"; font.pixelSize: 17; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                }

                Label {
                    x: 10
                    width: 210
                    text: shell.folder || I18n.tr("No folder selected")
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                }
                Item { width: 1; height: 8 }
                Label { x: 10; text: I18n.tr("Before changes"); color: Theme.dim; font.pixelSize: 12; font.weight: 700 }
                Repeater {
                    model: shell.beforeRows
                    delegate: Item {
                        required property var modelData
                        width: 220
                        height: 27
                        Glyph { x: 10; name: modelData.icon; font.pixelSize: 15; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Label { x: 36; width: 146; text: I18n.tr(modelData.name); color: Theme.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        Label { anchors.right: parent.right; anchors.rightMargin: 8; text: modelData.value; color: Theme.cream; font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Item { width: 1; height: 9 }
                Rectangle {
                    width: 220
                    height: 40
                    radius: 13
                    color: Theme.raised
                    opacity: 0.58
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Glyph { name: "sparkles"; color: Theme.faint; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: I18n.tr("Sort!"); color: Theme.faint; font.weight: 700; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Label {
                    x: 10
                    width: 210
                    text: I18n.tr("AI analysis is not available yet.")
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.settingsError !== "" || (shell.automaticPreviews && shell.memoryError !== "")
                    text: shell.settingsError !== "" ? shell.settingsError : shell.memoryError
                    color: Theme.red
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        ]
        foot: [
            Rectangle {
                id: folderBadge
                x: 40
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width - 58, Math.max(168, folderNameLabel.implicitWidth + 26))
                height: 34
                radius: 11
                color: Qt.rgba(0, 0, 0, 0.38)
                border.width: 1
                border.color: Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.72)
            },
            Glyph { x: 22; name: "folder"; color: Theme.gold; anchors.verticalCenter: parent.verticalCenter },
            Label {
                id: folderNameLabel
                x: folderBadge.x + 13
                width: folderBadge.width - 26
                anchors.verticalCenter: parent.verticalCenter
                text: shell.folderName
                color: Theme.inkOnCoffee
                font.pixelSize: 13
                font.weight: 700
                elide: Text.ElideMiddle
                Accessible.name: shell.folder
            }
        ]

        Scroll {
            Column {
                width: parent.width
                spacing: 12

                Rectangle {
                    id: instructionBox
                    width: parent.width
                    height: 104
                    radius: 16
                    color: Theme.card
                    border.width: instructionInput.activeFocus ? 1 : 0
                    border.color: Theme.gold

                    TextEdit {
                        id: instructionInput
                        x: 16
                        y: 12
                        width: parent.width - 32
                        height: parent.height - 24
                        text: shell.sortingInstruction
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        color: Theme.cream
                        selectionColor: Theme.coffee
                        font.family: Theme.font
                        font.pixelSize: 13
                        selectByMouse: true
                        clip: true
                        Accessible.name: I18n.tr("Sorting instructions")
                        onTextChanged: shell.sortingInstruction = text
                    }
                    Label {
                        x: instructionInput.x
                        y: instructionInput.y
                        width: instructionInput.width
                        height: instructionInput.height
                        visible: instructionInput.text.length === 0
                        text: I18n.tr("Describe how to sort these files—for example, photos by people or GPS location, episodes by series title and season number, films by genre, or music by style and band.")
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignTop
                        Accessible.ignored: true
                        enabled: false
                    }
                }

                Item {
                    id: pileColumn
                    width: parent.width
                    height: Math.max(460, parent.height - instructionBox.height - 36)

                    Item {
                        id: pile
                        anchors.fill: parent
                        clip: true

                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: !shell.result || shell.result.files.length === 0
                            text: shell.scanning
                                  ? I18n.tr("Reading folder…")
                                  : shell.scanError
                                    ? shell.scanError
                                    : (shell.folder ? I18n.tr("This folder has no visible files.") : I18n.tr("No folder selected"))
                            color: shell.scanError ? Theme.red : Theme.faint
                        }

                        Repeater {
                            model: shell.result ? shell.result.files : []
                            delegate: Rectangle {
                                required property int index
                                required property var modelData
                                readonly property bool isPhoto: modelData.kind === "photo"
                                readonly property real spreadX: ((index * 47) % 151) - 75
                                readonly property real spreadY: ((index * 31) % 111) - 55
                                width: 82
                                height: 98
                                x: Math.max(4, Math.min(pile.width - width - 4,
                                     pile.width * 0.5 - width * 0.5 + (shell.pileSettled ? spreadX : 0)))
                                y: Math.max(4, Math.min(pile.height - height - 4,
                                     pile.height * 0.5 - height * 0.5 + (shell.pileSettled ? spreadY : 0)))
                                rotation: shell.pileSettled ? (index * 17) % 25 - 12 : 0
                                z: index + 1
                                color: Theme.raised
                                border.width: 1
                                border.color: Theme.line
                                Behavior on x { NumberAnimation { duration: 160 + index * 12; easing.type: Easing.OutCubic } }
                                Behavior on y { NumberAnimation { duration: 160 + index * 12; easing.type: Easing.OutCubic } }
                                Behavior on rotation { NumberAnimation { duration: 220 + index * 10; easing.type: Easing.OutCubic } }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: parent.isPhoto
                                    source: parent.isPhoto ? shell.fileUrl(parent.modelData.path) : ""
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 164
                                    sourceSize.height: 196
                                    smooth: true
                                }
                                Glyph {
                                    anchors.centerIn: parent
                                    visible: !parent.isPhoto
                                    name: parent.modelData.kind === "video" ? "video"
                                          : parent.modelData.kind === "audio" ? "music" : "file"
                                    font.pixelSize: 25
                                    color: Theme.gold
                                }
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 28
                                    radius: 8
                                    color: Theme.surface
                                    Label {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        text: parent.parent.modelData.name
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: previousPage
                            width: 42
                            height: 42
                            radius: 21
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            visible: shell.result !== null && shell.pageOffset > 0
                            color: Theme.card
                            Accessible.name: I18n.tr("Previous")
                            Accessible.role: Accessible.Button
                            Glyph { anchors.centerIn: parent; name: "chevron-left"; color: Theme.cream }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !shell.scanning
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shell.pageOffset = Math.max(0, shell.pageOffset - shell.previewLimit)
                                    shell.scan()
                                }
                            }
                        }
                        Rectangle {
                            id: nextPage
                            width: 42
                            height: 42
                            radius: 21
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 16
                            visible: shell.result !== null && shell.result.has_more
                            color: Theme.card
                            Accessible.name: I18n.tr("Next")
                            Accessible.role: Accessible.Button
                            Glyph { anchors.centerIn: parent; name: "chevron-right"; color: Theme.cream }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !shell.scanning
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shell.pageOffset += shell.previewLimit
                                    shell.scan()
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: menuOverlay
            anchors.fill: parent
            z: 1000
            Menu { id: modelMenu }
        }
    }
}
