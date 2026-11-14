-- Widgets and new Goo (goo/widgets.plm, ROADMAP 6.47): the creations of pleamar-wm's Build mode, as `latte-goowidgets list`
-- reads them. Keeping, replacing and deleting stay in Build's own list; this window shows them and starts Build.
local function N(s) return s end
local KINDS = { widget = N("Widget"), bar = N("Bar"), dock = N("Dock"), app = N("App") }

text.o_title = tr("Widgets and new Goo")
text.o_note = tr("The gadgets the AI builds for you in pleamar's Build mode (Win+B). Foreign Goo comes later.")
text.o_none = tr("Nothing built yet. Press Build something, draw where it should go and say what it should be.")
text.o_build = tr("Build something")
text.o_folder = tr("Open the folder")
text.o_refresh = tr("Refresh")
text.o_close = tr("Close")

local function load()
    run("latte-goowidgets", { "list" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        local rows = {}
        if ok and type(list) == "table" then
            for _, c in ipairs(list) do
                rows[#rows + 1] = { name = tostring(c.name or c.id), kind = tr(KINDS[c.kind] or tostring(c.kind or "")),
                                    kept = c.session == true, state = c.session and tr("Starts with the session") or tr("Not kept") }
            end
        end
        model.crea = rows
        fact.o_n = #rows
    end)
end

on("refresh", load)
on("folder", function() run("latte-goowidgets", { "folder" }, nil, { output = false }) end)
on("build", function() run("latte-goowidgets", { "build" }, nil, { output = false }) emit("cancel") end)

require("lib/cup").start()
load()
