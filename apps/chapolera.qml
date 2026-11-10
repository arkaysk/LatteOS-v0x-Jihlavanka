//@ pragma AppId latteos-chapolera
import QtQuick
import Quickshell
import Quickshell.Io
import "common"

ShellRoot {
    id: shell

    // a folder: name, how many files, and a row of thumbnails that pop in one after another
    component CategoryCard: Rectangle {
        id: card
        property int order: 0
        property string name: ""
        property int count: 0
        property var thumbs: []
        property bool ready: false
        property int shownCount: 0
        property real slide: 0
        property real from: 36
        signal placed(string name, point where)
        height: 92
        radius: 16
        color: Theme.card
        border.width: 1
        border.color: shell.plan ? Theme.gold : Theme.line
        opacity: 0
        transform: Translate { x: card.slide }
        Component.onCompleted: { slide = from; enter.start() }
        SequentialAnimation {
            id: enter
            PauseAnimation { duration: Math.min(card.order, 8) * 90 }
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 320 }
                NumberAnimation { target: card; property: "slide"; to: 0; duration: 440; easing.type: Easing.OutCubic }
                NumberAnimation { target: card; property: "shownCount"; to: card.count; duration: 800; easing.type: Easing.OutCubic }
            }
        }
        Timer { interval: Math.min(card.order, 8) * 90 + 250; running: true; onTriggered: card.ready = true }
        // once the card has settled it says where it is: the tiles of its files fly there
        Timer {
            interval: Math.min(card.order, 8) * 90 + 120
            running: true
            onTriggered: {
                const spot = card.mapToItem(null, card.width / 2, card.height / 2)
                card.placed(card.name, Qt.point(spot.x - card.slide, spot.y))
            }
        }
        Glyph { x: 14; y: 10; name: "folder"; font.pixelSize: 15; color: Theme.gold }
        Label {
            x: 38
            y: 9
            width: card.width - 90
            text: card.name
            color: Theme.cream
            font.pixelSize: 13
            font.weight: 700
            elide: Text.ElideRight
        }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 9
            text: String(card.shownCount)
            color: Theme.gold
            font.pixelSize: 14
            font.weight: 700
        }
        Row {
            x: 14
            y: 38
            spacing: 5
            Repeater {
                model: card.thumbs.slice(0, 6)
                delegate: Rectangle {
                    id: thumb
                    required property int index
                    required property string modelData
                    property bool shown: false
                    width: Math.floor((card.width - 28 - 5 * 5) / 6)
                    height: 42
                    radius: 7
                    color: Theme.raised
                    clip: true
                    opacity: shown ? 1 : 0
                    scale: shown ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                    Timer { interval: thumb.index * 70; running: card.ready; onTriggered: thumb.shown = true }
                    Image {
                        anchors.fill: parent
                        source: shell.fileUrl(thumb.modelData)
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 96
                        sourceSize.height: 96
                    }
                }
            }
        }
    }

    // one figure of the bar on top; the number counts up to its value
    component StatTile: Rectangle {
        property string caption: ""
        property int value: 0
        property int shown: value
        Behavior on shown { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
        height: 62
        radius: 14
        color: Theme.card
        Label { x: 14; y: 9; text: parent.caption; color: Theme.faint; font.pixelSize: 10; font.weight: 600 }
        Label { x: 14; y: 26; text: String(parent.shown); color: Theme.cream; font.pixelSize: 22; font.weight: 700 }
    }

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
    property string taggingInstruction: ""
    property string analysisState: "idle"
    property string analysisError: ""
    property string classifierOutputError: ""
    property int analysisTotal: 0
    property int analysisCompleted: 0
    property var suggestedTags: []
    property bool receivedCompleteEvent: false
    property int skippedPhotos: 0
    property string sampleNames: ""
    property var baseVocabulary: []
    property string vocabularyNote: ""
    // where each folder card stands (scene coordinates), so the tiles of the pile can fly into it
    property var cardTargets: ({})
    onPlanChanged: if (!plan) cardTargets = ({})
    function registerCard(name, point) {
        const next = Object.assign({}, cardTargets)
        next[name] = point
        cardTargets = next
    }
    property int dupExtra: 0
    property var dupThumbs: []
    // What the right-hand column shows: the folders of a plan, or the tags found so far.
    readonly property var cards: plan
        ? plan.categories.map(c => ({ name: c.name, count: c.count, thumbs: c.samples.map(n => folder + "/" + n) }))
        : analysisState === "complete"
          ? suggestedTags.filter(t => t.count > 0).map(t => ({ name: t.label, count: t.count, thumbs: t.previews }))
          : []
    readonly property bool sortedNow: planState === "applied"
    property bool cloudAsk: false
    property bool cloudConfirmed: false
    readonly property string sheetPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/latte-chapolera-sheet.jpg"
    // Only a model that can look at pictures can name what is in THIS folder; a text-only one would just guess.
    readonly property bool modelSees: !!selectedProvider && !!selectedModel
                                      && (!selectedProvider.local || selectedModel.vision === true)
    // Folder plan: "idle" | "planning" | "proposed" | "moving" | "applied" | "undoing" | "error"
    property string planState: "idle"
    property var plan: null
    property string planFolder: ""
    property string planError: ""
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
    readonly property bool analysisBusy: analysisState === "planning" || analysisState === "tagging"
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
        // A proposal belongs to the folder it was made for; another folder must not inherit it.
        if (plan && folder !== planFolder) {
            plan = null
            planState = "idle"
        }
        if (!folder || !settingsReady || (automaticPreviews && !memoryReady)) return
        if (analysisBusy) return
        if (scanner.running) {
            pendingScan = true
            return
        }
        scanning = true
        pileSettled = false
        scanError = ""
        result = null
        scanner.buf = ""
        // quick: the folder appears at once; ExifTool and the like run afterwards in the background (enrich)
        scanner.command = ["latte-chapolera", "scan", folder, String(previewLimit), String(pageOffset), "quick"]
        scanner.running = true
    }

    function startTagging() {
        if (analysisBusy || !folder || !result) return
        if (selectedProvider && !selectedProvider.local && selectedModel && !cloudConfirmed) {
            // Cloud only after an explicit second click; the sidebar says what leaves the computer.
            if (!cloudAsk) {
                cloudAsk = true
                return
            }
            cloudConfirmed = true
        }
        if (counts.photos === 0) {
            analysisError = I18n.tr("This step can tag photos only. Other media types are not analyzed yet.")
            return
        }

        analysisError = ""
        classifierOutputError = ""
        analysisTotal = 0
        analysisCompleted = 0
        suggestedTags = []
        skippedPhotos = 0
        receivedCompleteEvent = false
        analysisState = "planning"
        sampleNames = ""
        cloudAsk = false
        vocabularyNote = ""
        baseVocabularyReader.buf = ""
        baseVocabularyReader.running = true
    }

    // The built-in visual vocabulary is always used; the model only adds what is specific to this collection.
    function onBaseVocabulary(text) {
        try {
            baseVocabulary = JSON.parse(text)
        } catch (error) {
            failAnalysis(I18n.tr("The built-in tag vocabulary could not be read."))
            return
        }
        if (!selectedProvider || !selectedModel) {
            startClassifier([])
        } else if (!modelSees) {
            vocabularyNote = I18n.tr("This model cannot see pictures, so the built-in vocabulary was used. Pick a model with vision (for example Claude) for tags made for this folder.")
            startClassifier([])
        } else {
            namesReader.running = true
        }
    }

    function askForVocabulary() {
        tagPlanner.buf = ""
        tagPlanner.command = [
            "latte-ai", "send", "new", selectedProviderId, selectedModelId,
            tagPrompt(), "--attach", sheetPath, "--from", "chapolera"
        ]
        tagPlanner.running = true
    }

    function tagPrompt() {
        const prompt = taggingInstruction.trim() || "Describe the visible subjects and scenes in these photos."
        return [
            "You prepare a visual tag vocabulary for a photo analyzer. The attached image is a contact sheet of a sample of the files in the folder; the file names below are only a hint.",
            "The user writes in Slovak. Respect the user's tagging instruction.",
            "Propose descriptive tags, not categories, folders, or groups. Each tag should name one visible subject, scene, activity, or visual quality.",
            "Only describe visible image content. Do not claim to know people's identities, GPS locations, or hidden metadata.",
            "Look at what the pictures really show and propose tags specific to THIS collection, not generic words.",
            "Return only one valid JSON object, with no Markdown, in this exact shape:",
            "{\"tags\":[{\"label\":\"short Slovak tag\",\"image_prompt\":\"short English visual description\"}]}",
            "Create 4 to 16 distinct tags. The label MUST be a Slovak word or phrase (never English); it must not contain slashes or control characters.",
            "The image_prompt must be a short English phrase describing visible content; do not start it with 'a photo of'.",
            "If the instruction depends on GPS or named-person recognition, use visual descriptions only and do not imply that those unavailable facts were checked.",
            "Tagging instruction: " + prompt,
            "Visible inventory: " + counts.photos + " photos, " + counts.videos + " videos, " + counts.audio + " audio files, " + counts.other + " other files.",
            "This stage analyzes photos only; do not propose categories for other media.",
            "Sample file names: " + sampleNames
        ].join("\n")
    }

    // Models drift: fences, a cut-off tail, repeated entries. Keep every valid, distinct tag and drop the rest.
    function parseModelTags(answer) {
        const found = []
        try {
            const first = answer.indexOf("{")
            const last = answer.lastIndexOf("}")
            const payload = JSON.parse(answer.slice(first, last + 1))
            if (payload && Array.isArray(payload.tags)) found.push(...payload.tags)
        } catch (error) {
            const pattern = /\{\s*"label"\s*:\s*"([^"]*)"\s*,\s*"image_prompt"\s*:\s*"([^"]*)"\s*\}/g
            let match
            while ((match = pattern.exec(answer)) !== null) found.push({ label: match[1], image_prompt: match[2] })
        }
        const names = []
        const prompts = []
        const tags = []
        for (const tag of found) {
            if (!tag || typeof tag.label !== "string" || typeof tag.image_prompt !== "string") continue
            const label = tag.label.trim()
            const imagePrompt = tag.image_prompt.trim()
            if (label.length === 0 || label.length > 64 || /[\/\\\u0000-\u001f]/.test(label)
                    || imagePrompt.length === 0 || imagePrompt.length > 200) continue
            const nameKey = label.toLocaleLowerCase()
            const promptKey = imagePrompt.toLocaleLowerCase()
            if (names.includes(nameKey) || prompts.includes(promptKey)) continue
            names.push(nameKey)
            prompts.push(promptKey)
            tags.push({ label, image_prompt: imagePrompt })
            if (tags.length === 12) break
        }
        return tags
    }

    function acceptProposedTags(answer) {
        const modelTags = parseModelTags(answer)
        // Fewer than three usable tags means the model did not follow the task: the built-in vocabulary carries on alone.
        if (modelTags.length < 3) {
            vocabularyNote = I18n.tr("The model's tag suggestions were unusable, so the built-in vocabulary was used.")
            startClassifier([])
        } else {
            startClassifier(modelTags)
        }
    }

    function startClassifier(modelTags) {
        const names = modelTags.map(tag => tag.label.toLocaleLowerCase())
        const prompts = modelTags.map(tag => tag.image_prompt.toLocaleLowerCase())
        const candidates = modelTags.slice()
        // Built-in words are a fallback for a model that gave nothing; they never dilute tags made for this folder.
        for (const base of modelTags.length === 0 ? baseVocabulary : []) {
            const label = I18n.tr(base.label)
            if (names.includes(label.toLocaleLowerCase()) || prompts.includes(base.image_prompt.toLocaleLowerCase())) continue
            candidates.push({ label, image_prompt: base.image_prompt })
        }
        suggestedTags = candidates.map(tag => ({ label: tag.label, imagePrompt: tag.image_prompt, count: 0, previews: [] }))
        analysisState = "tagging"
        classifierOutputError = ""
        const vocabularyModelId = selectedProvider && selectedModel && modelTags.length > 0
            ? selectedProviderId + "/" + selectedModelId : "built-in"
        classifier.command = [
            "latte-chapolera", "tag-folder-events", folder, vocabularyModelId, JSON.stringify(candidates)
        ]
        classifier.running = true
    }

    function acceptClassifierEvent(line) {
        let event
        try {
            event = JSON.parse(line)
        } catch (error) {
            failAnalysis(I18n.tr("The photo tagger returned invalid progress data."))
            return
        }
        if (!event || typeof event.event !== "string") {
            failAnalysis(I18n.tr("The photo tagger returned invalid progress data."))
            return
        }
        if (event.event === "start") {
            if (!Number.isInteger(event.total) || event.total !== counts.photos) {
                failAnalysis(I18n.tr("The photo count changed while tagging. Scan the folder again."))
                return
            }
            analysisTotal = event.total
            analysisCompleted = 0
            return
        }
        if (event.event === "image") {
            if (analysisCompleted >= analysisTotal) {
                failAnalysis(I18n.tr("The photo tagger returned too many photo results."))
                return
            }
            if (typeof event.image !== "string" || !Array.isArray(event.tags) || event.tags.length === 0) {
                failAnalysis(I18n.tr("The photo tagger returned an invalid result."))
                return
            }
            const tags = suggestedTags.slice()
            const imageTags = []
            for (const result of event.tags) {
                if (!result || typeof result.label !== "string"
                        || typeof result.confidence !== "number" || !Number.isFinite(result.confidence)
                        || result.confidence < 0 || result.confidence > 1) {
                    failAnalysis(I18n.tr("The photo tagger returned an invalid tag."))
                    return
                }
                const tagIndex = tags.findIndex(tag => tag.label === result.label)
                if (tagIndex < 0 || imageTags.includes(tagIndex)) {
                    failAnalysis(I18n.tr("The photo tagger returned an invalid tag."))
                    return
                }
                imageTags.push(tagIndex)
                const tag = Object.assign({}, tags[tagIndex])
                tag.count += 1
                if (tag.previews.length < 4) tag.previews = tag.previews.concat([event.image])
                tags[tagIndex] = tag
            }
            suggestedTags = tags
            analysisCompleted += 1
            return
        }
        if (event.event === "skipped") {
            // An unreadable photo is counted as done, so one bad file does not stop the run.
            skippedPhotos += 1
            analysisCompleted += 1
            return
        }
        if (event.event === "complete") {
            if (!Number.isInteger(event.classified) || event.classified !== analysisTotal
                    || analysisCompleted !== analysisTotal) {
                failAnalysis(I18n.tr("The photo tagger did not return every photo."))
                return
            }
            receivedCompleteEvent = true
            analysisState = "complete"
            Qt.callLater(suggestFolders)   // the sorting proposal follows the tagging without another click
            return
        }
        failAnalysis(I18n.tr("The photo tagger returned an unknown event."))
    }

    function runPlan(args, state) {
        planFolder = folder
        planError = ""
        planState = state
        planner.command = ["latte-chapolera"].concat(args)
        planner.running = true
    }

    function suggestFolders() {
        if (planState === "planning" || planState === "moving" || planState === "undoing" || planState === "cancelling" || !folder) return
        plan = null
        runPlan(["plan", folder], "planning")
    }

    function acceptPlanReply(text) {
        const reply = JSON.parse(text)
        if (planState === "planning") {
            if (!reply || !Number.isInteger(reply.plan_id) || !Array.isArray(reply.categories))
                throw new Error("Invalid plan")
            plan = reply
            planState = "proposed"
        } else if (planState === "moving") {
            plan = Object.assign({}, plan, { moved: reply.moved, failed: reply.failed })
            planState = "applied"
            scan()
        } else if (planState === "undoing") {
            plan = null
            planState = "idle"
            scan()
        } else if (planState === "cancelling") {
            plan = null
            planState = "idle"
        }
    }

    function failAnalysis(message) {
        analysisState = "error"
        analysisError = message
        suggestedTags = []
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
                text: I18n.tr("No model (built-in vocabulary only)"),
                icon: "sparkles",
                checked: selectedProviderId === "",
                run: () => shell.chooseModel("", "")
            })
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
        cloudAsk = false
        cloudConfirmed = false
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
                // Claude Haiku is the default: cheap, quick and it sees the pictures (a local model can be picked).
                const haiku = valid.find(provider => provider.id === "claude"
                    && provider.models.some(model => model.id === "haiku"))
                const initial = selected || haiku || valid[0]
                shell.selectedProviderId = initial.id
                shell.selectedModelId = selected ? shell.selectedModelId
                                                 : (initial === haiku ? "haiku" : initial.models[0].id)
            } catch (error) {
                shell.modelError = I18n.tr("LensAI returned an invalid provider list.")
            }
        }
    }

    Process {
        id: baseVocabularyReader
        property string buf: ""
        command: ["latte-chapolera", "base-vocabulary"]
        stdout: StdioCollector { onStreamFinished: baseVocabularyReader.buf = this.text }
        onExited: code => {
            if (shell.analysisState !== "planning") return
            if (code !== 0) shell.failAnalysis(I18n.tr("The built-in tag vocabulary could not be read."))
            else shell.onBaseVocabulary(buf)
        }
    }

    Process {
        id: namesReader
        property string buf: ""
        command: ["latte-chapolera", "sample-names", shell.folder, "60"]
        stdout: StdioCollector { onStreamFinished: namesReader.buf = this.text }
        onExited: code => {
            if (shell.analysisState !== "planning") return
            // The names only sharpen the vocabulary; without them the model still gets the instruction.
            try {
                if (code === 0) shell.sampleNames = JSON.parse(buf).names.join("; ")
            } catch (error) {
                shell.sampleNames = ""
            }
            sheetMaker.running = true
        }
    }

    Process {
        id: sheetMaker
        command: ["latte-chapolera", "contact-sheet", shell.folder, "12", shell.sheetPath]
        onExited: code => {
            if (shell.analysisState !== "planning") return
            if (code !== 0) {
                shell.vocabularyNote = I18n.tr("The model could not suggest tags, so the built-in vocabulary was used.")
                shell.startClassifier([])
                return
            }
            shell.askForVocabulary()
        }
    }

    Process {
        id: tagPlanner
        property string buf: ""
        stdout: StdioCollector { onStreamFinished: tagPlanner.buf = this.text }
        onExited: code => {
            if (shell.analysisState !== "planning") return
            try {
                const response = JSON.parse(buf)
                if (code !== 0 || !response || response.ok !== true || typeof response.answer !== "string")
                    throw new Error("The model returned no answer")
                shell.acceptProposedTags(response.answer)
            } catch (error) {
                // A model that is off, out of limit or confused must not block the tagging itself.
                shell.vocabularyNote = I18n.tr("The model could not suggest tags, so the built-in vocabulary was used.")
                shell.startClassifier([])
            }
        }
    }

    Process {
        id: classifier
        stdout: SplitParser { onRead: line => shell.acceptClassifierEvent(line) }
        onExited: code => {
            if (shell.analysisState === "error") return
            if (code !== 0) {
                shell.failAnalysis(I18n.tr("SigLIP 2 could not analyze the photos (exit code {code}).", { code }))
                return
            }
            if (!shell.receivedCompleteEvent)
                shell.failAnalysis(I18n.tr("SigLIP 2 finished without a complete result."))
        }
    }

    Process {
        id: enricher
        command: ["latte-chapolera", "enrich", shell.folder]
    }

    Process {
        id: duplicatesReader
        property string buf: ""
        command: ["latte-chapolera", "duplicates", shell.folder]
        stdout: StdioCollector { onStreamFinished: duplicatesReader.buf = this.text }
        onExited: code => {
            if (code !== 0) return
            try {
                let extra = 0
                const thumbs = []
                for (const group of JSON.parse(buf).groups) {
                    extra += group.paths.length - 1
                    for (const path of group.paths.slice(1)) if (thumbs.length < 8) thumbs.push(path)
                }
                shell.dupExtra = extra
                shell.dupThumbs = thumbs
            } catch (error) {
                shell.dupExtra = 0
            }
        }
    }

    Process {
        id: planner
        property string buf: ""
        stdout: StdioCollector { onStreamFinished: planner.buf = this.text }
        stderr: StdioCollector { id: plannerErr }
        onExited: code => {
            if (code !== 0) {
                const wasUndo = shell.planState === "undoing"
                shell.planError = plannerErr.text.trim() || I18n.tr("The folder plan failed (exit code {code}).", { code })
                shell.planState = wasUndo ? "applied" : (shell.plan ? "proposed" : "error")
                return
            }
            try {
                shell.acceptPlanReply(buf)
            } catch (error) {
                shell.planError = I18n.tr("The folder plan returned invalid data.")
                shell.planState = "error"
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
                    if (!duplicatesReader.running) duplicatesReader.running = true
                    if (!enricher.running) enricher.running = true
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
        heading: I18n.tr("Tagging with:")
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
                        : shell.selectedProviderId === "" && shell.aiProviders.length > 0
                          ? I18n.tr("No model (built-in vocabulary only)")
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
                    id: tagButton
                    width: 220
                    height: 40
                    radius: 13
                    color: shell.analysisBusy ? Theme.raised : Theme.gold
                    opacity: shell.analysisBusy || !shell.result ? 0.58 : 1
                    Accessible.name: I18n.tr("Tag photos")
                    Accessible.role: Accessible.Button
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Glyph {
                            name: shell.analysisBusy ? "loader-2" : "sparkles"
                            color: shell.analysisBusy ? Theme.faint : Theme.inkOnCoffee
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: shell.analysisBusy ? I18n.tr("Analyzing…") : I18n.tr("Tag photos")
                            color: shell.analysisBusy ? Theme.faint : Theme.inkOnCoffee
                            font.weight: 700
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !!shell.result && !shell.analysisBusy
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: shell.startTagging()
                    }
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.analysisState === "planning"
                    text: I18n.tr("Preparing visual tag candidates with the local model…")
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.analysisState === "tagging"
                    text: I18n.tr("Tagging photos: {done} of {total}", {
                        done: shell.analysisCompleted,
                        total: shell.analysisTotal
                    })
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.cloudAsk && shell.analysisState === "idle"
                    text: I18n.tr("A contact sheet of small thumbnails of about 12 of your photos, a few file names and your instruction go to {provider}. The other photos stay on this computer. Press Tag photos again to continue.", { provider: shell.selectedProvider ? shell.selectedProvider.name : "" })
                    color: Theme.gold
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.vocabularyNote !== "" && shell.analysisState !== "idle"
                    text: shell.vocabularyNote
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Rectangle {
                    id: planButton
                    width: 220
                    height: 40
                    radius: 13
                    visible: shell.analysisState === "complete" && shell.planState !== "applied"
                    color: Theme.gold
                    opacity: shell.planState === "planning" || shell.planState === "moving" ? 0.58 : 1
                    Accessible.name: shell.planState === "proposed" ? I18n.tr("Execute changes") : I18n.tr("Suggest folders")
                    Accessible.role: Accessible.Button
                    Label {
                        anchors.centerIn: parent
                        text: shell.planState === "planning" ? I18n.tr("Planning…")
                              : shell.planState === "moving" ? I18n.tr("Moving…")
                              : shell.planState === "proposed" ? I18n.tr("Execute changes")
                              : I18n.tr("Suggest folders")
                        color: Theme.inkOnCoffee
                        font.weight: 700
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: ["idle", "proposed", "error"].includes(shell.planState)
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (shell.planState === "proposed") shell.runPlan(["plan-apply", String(shell.plan.plan_id)], "moving")
                            else shell.suggestFolders()
                        }
                    }
                }
                Rectangle {
                    width: 220
                    height: 34
                    radius: 11
                    visible: shell.planState === "proposed" || shell.planState === "applied"
                    color: Theme.raised
                    Label {
                        anchors.centerIn: parent
                        text: shell.planState === "applied" ? I18n.tr("Undo the move") : I18n.tr("Discard the proposal")
                        color: Theme.cream
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!planner.running) shell.runPlan([shell.planState === "applied" ? "plan-undo" : "plan-cancel", String(shell.plan.plan_id)],
                                                 shell.planState === "applied" ? "undoing" : "cancelling")
                    }
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.planState === "proposed"
                    text: I18n.tr("{n} files stay where they are for your review. Nothing moves until you confirm, and the move can be undone.", { n: shell.plan ? shell.plan.review + shell.plan.conflicts : 0 })
                    color: Theme.faint
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.planState === "applied"
                    text: I18n.tr("Moved {n} files. {failed} could not be moved.", { n: shell.plan ? shell.plan.moved : 0, failed: shell.plan ? shell.plan.failed : 0 })
                    color: Theme.gold
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.planError !== ""
                    text: shell.planError
                    color: Theme.red
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.analysisState === "complete" && shell.skippedPhotos > 0
                    text: I18n.tr("{n} photos could not be read and were skipped.", { n: shell.skippedPhotos })
                    color: Theme.red
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.analysisState === "complete"
                    text: I18n.tr("Tags are ranked by relative visual similarity, not calibrated probabilities.")
                    color: Theme.gold
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: true
                    text: I18n.tr("Photos are analyzed for visible content only, not GPS or named-person identity. A local model stays on this computer; a cloud model gets a small contact sheet only after you confirm.")
                    color: Theme.faint
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: true
                    text: I18n.tr("Videos, audio and documents are left unchanged in this step.")
                    color: Theme.faint
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
                Label {
                    x: 10
                    width: 210
                    visible: shell.analysisError !== ""
                    text: shell.analysisError
                    color: Theme.red
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

                Row {
                    id: statsBar
                    width: parent.width
                    spacing: 10
                    readonly property real tile: (width - 4 * spacing) / 5
                    StatTile { width: statsBar.tile; caption: I18n.tr("Total files"); value: shell.counts.total }
                    StatTile { width: statsBar.tile; caption: I18n.tr("Videos"); value: shell.counts.videos }
                    StatTile { width: statsBar.tile; caption: I18n.tr("Photos"); value: shell.counts.photos }
                    StatTile { width: statsBar.tile; caption: I18n.tr("Folders created"); value: shell.plan ? shell.plan.categories.length : 0 }
                    StatTile { width: statsBar.tile; caption: I18n.tr("Duplicates found"); value: shell.dupExtra }
                }
                Rectangle {
                    // progress while the photos are being tagged
                    width: statsBar.width * (shell.analysisTotal > 0 ? shell.analysisCompleted / shell.analysisTotal : 0)
                    height: shell.analysisBusy ? 3 : 0
                    radius: 2
                    color: Theme.gold
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
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
                        text: shell.taggingInstruction
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        color: Theme.cream
                        selectionColor: Theme.coffee
                        font.family: Theme.font
                        font.pixelSize: 13
                        selectByMouse: true
                        clip: true
                        Accessible.name: I18n.tr("Tagging instructions")
                        onTextChanged: shell.taggingInstruction = text
                    }
                    Label {
                        x: instructionInput.x
                        y: instructionInput.y
                        width: instructionInput.width
                        height: instructionInput.height
                        visible: instructionInput.text.length === 0
                        text: I18n.tr("Describe visual details to tag—for example, landscapes, family gatherings, pets, architecture, or sports. GPS and named-person identity are not analyzed.")
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
                    height: 320    // the coffee at the foot of the window covers what lies lower

                    readonly property bool showCards: shell.cards.length > 0

                    Item {
                        id: pile
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        // the pile makes room for the folders on both sides; the tiles follow because they are placed from this width
                        width: pileColumn.showCards ? Math.round(parent.width * 0.32) : parent.width
                        Behavior on width { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

                        Rectangle {
                            // a soft pulse behind the pile while it is being read
                            anchors.centerIn: parent
                            width: 260
                            height: 260
                            radius: 130
                            color: Theme.gold
                            opacity: 0
                            SequentialAnimation on opacity {
                                running: shell.analysisBusy
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.16; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.04; duration: 900; easing.type: Easing.InOutSine }
                                onRunningChanged: if (!running) parent.opacity = 0
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: shell.analysisState !== "complete"
                                     && (!shell.result || shell.result.files.length === 0)
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
                                // the folder this file is going to, and where that folder's card stands
                                readonly property int folderIndex: shell.plan && shell.plan.assignments
                                                                   && shell.plan.assignments[modelData.name] !== undefined
                                                                   ? shell.plan.assignments[modelData.name] : -1
                                readonly property string folderName: folderIndex >= 0 && shell.plan.categories[folderIndex]
                                                                     ? shell.plan.categories[folderIndex].name : ""
                                readonly property var landing: folderName !== "" && shell.cardTargets[folderName]
                                                               ? pile.mapFromItem(null, shell.cardTargets[folderName].x, shell.cardTargets[folderName].y)
                                                               : null
                                readonly property bool flying: landing !== null
                                readonly property int lag: Math.min(index, 40) * 30
                                width: 82
                                height: 98
                                x: flying ? landing.x - width / 2
                                   : Math.max(4, Math.min(pile.width - width - 4,
                                     pile.width * 0.5 - width * 0.5 + (shell.pileSettled ? spreadX : 0)))
                                y: flying ? landing.y - height / 2
                                   : Math.max(4, Math.min(pile.height - height - 4,
                                     // what stays for review settles a little lower, under the words
                                     pile.height * 0.5 - height * 0.5 + (shell.plan ? 22 : 0) + (shell.pileSettled ? spreadY : 0)))
                                rotation: shell.pileSettled ? (index * 17) % 25 - 12 : 0
                                opacity: flying ? 0 : 1
                                scale: flying ? 0.4 : 1
                                transformOrigin: Item.Center
                                // a tile flies to its folder one after another, shrinks on the way and is gone when it arrives
                                Behavior on opacity { SequentialAnimation {
                                    PauseAnimation { duration: flying ? lag + 560 : 0 }
                                    NumberAnimation { duration: flying ? 260 : 300 } } }
                                Behavior on scale { SequentialAnimation {
                                    PauseAnimation { duration: flying ? lag : 0 }
                                    NumberAnimation { duration: flying ? 760 : 300; easing.type: Easing.InOutCubic } } }
                                z: index + 1
                                color: Theme.raised
                                border.width: 1
                                border.color: Theme.line
                                Behavior on x { SequentialAnimation {
                                    PauseAnimation { duration: flying ? lag : 0 }
                                    NumberAnimation { duration: flying ? 760 : 160 + index * 12; easing.type: flying ? Easing.InOutCubic : Easing.OutCubic } } }
                                Behavior on y { SequentialAnimation {
                                    PauseAnimation { duration: flying ? lag : 0 }
                                    NumberAnimation { duration: flying ? 760 : 160 + index * 12; easing.type: flying ? Easing.InOutCubic : Easing.OutCubic } } }
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

                        // where the pile stood: a few words about what happens, no button (that is in the sidebar)
                        Column {
                            id: decision
                            anchors.top: parent.top
                            anchors.topMargin: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 24
                            spacing: 8
                            visible: shell.planState !== "idle" && shell.planState !== "error"
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 600 } }
                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: shell.sortedNow ? I18n.tr("{n} files sorted.", { n: shell.plan ? shell.plan.moved : 0 })
                                      : shell.planState === "planning" ? I18n.tr("Planning…")
                                      : shell.planState === "moving" ? I18n.tr("Moving…")
                                      : I18n.tr("{files} files into {folders} folders", {
                                            files: shell.plan ? shell.plan.files - shell.plan.review - shell.plan.conflicts : 0,
                                            folders: shell.plan ? shell.plan.categories.length : 0 })
                                color: Theme.cream
                                font.pixelSize: 20
                                font.weight: 700
                            }
                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                visible: shell.planState === "proposed" && shell.plan && shell.plan.review + shell.plan.conflicts > 0
                                text: I18n.tr("{n} files stay for your review", { n: shell.plan ? shell.plan.review + shell.plan.conflicts : 0 })
                                color: Theme.faint
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            id: dupTray
                            z: 5000
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 14
                            width: Math.min(parent.width - 32, 340)
                            height: 46
                            radius: 13
                            color: Theme.card
                            border.width: 1
                            border.color: Theme.line
                            visible: shell.dupExtra > 0
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 400 } }
                            Glyph { x: 12; name: "copy"; font.pixelSize: 15; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                            Label {
                                x: 36
                                text: I18n.tr("Duplicates")
                                color: Theme.cream
                                font.pixelSize: 12
                                font.weight: 600
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Row {
                                anchors.right: countBadge.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Repeater {
                                    model: shell.dupThumbs.slice(0, Math.max(0, Math.floor((dupTray.width - 150) / 31)))
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: 28
                                        height: 28
                                        radius: 6
                                        color: Theme.raised
                                        clip: true
                                        Image {
                                            anchors.fill: parent
                                            source: /\.(jpe?g|png|webp|gif|bmp)$/i.test(parent.modelData) ? shell.fileUrl(parent.modelData) : ""
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize.width: 56
                                            sourceSize.height: 56
                                        }
                                    }
                                }
                            }
                            Label {
                                id: countBadge
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(shell.dupExtra)
                                color: Theme.gold
                                font.pixelSize: 14
                                font.weight: 700
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
                            visible: shell.analysisState !== "complete" && shell.result !== null && shell.pageOffset > 0
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
                            visible: shell.analysisState !== "complete" && shell.result !== null && shell.result.has_more
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

                    // the folders stand on both sides of the pile, the biggest first, left then right
                    Repeater {
                        model: 2
                        delegate: Flickable {
                            id: side
                            required property int index
                            readonly property var mine: shell.cards.filter((card, position) => position % 2 === side.index)
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: side.index === 0 ? parent.left : pile.right
                            anchors.right: side.index === 0 ? pile.left : parent.right
                            anchors.leftMargin: side.index === 0 ? 0 : 12
                            anchors.rightMargin: side.index === 0 ? 12 : 0
                            visible: pileColumn.showCards
                            contentWidth: width
                            contentHeight: sideColumn.height + 8
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            Column {
                                id: sideColumn
                                width: parent.width
                                spacing: 10
                                Repeater {
                                    model: side.mine
                                    delegate: CategoryCard {
                                        required property int index
                                        required property var modelData
                                        width: sideColumn.width
                                        order: index * 2 + side.index
                                        from: side.index === 0 ? -36 : 36
                                        name: modelData.name
                                        count: modelData.count
                                        thumbs: modelData.thumbs
                                        onPlaced: (name, where) => shell.registerCard(name, where)
                                    }
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
