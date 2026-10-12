-- The password dialog. When a program wants to do something as root (install software, mount a disk, pkexec)
-- somebody has to ask whoever sits there for the password: the session's authentication agent. Watching
-- pleamar's `polkit` service makes this scene that agent, and the dialog is a card.
-- The scene is only the messenger: the answer goes to polkit's own helper, which asks the system; nothing
-- here learns whether it was right other than by being told, and nothing here gains a privilege.
local card = require("lib/card")
local M = {}

local asking = false                         -- our card is the one open

local function show(p)
    local rows = { { head = true, label = tr("PASSWORD NEEDED") },
                   { para = true, label = (p.message or "") ~= "" and p.message or (p.action or "") } }
    if (p.user or "") ~= "" then rows[#rows + 1] = { label = p.user, glyph = "user", quiet = true } end
    if (p.info or "") ~= "" then rows[#rows + 1] = { label = p.info, glyph = "bell", quiet = true } end
    if p.error == "wrong" then rows[#rows + 1] = { label = tr("Wrong password"), glyph = "alert-triangle", danger = true, quiet = true } end
    rows[#rows + 1] = { line = true, pills = { { label = tr("Cancel"), glyph = "x", run = function() asking = false pcall(sys.call, "polkit.cancel") end } } }
    -- It belongs to no drop: it comes up in the upper middle of the screen.
    fact["tap.x"], fact["tap.y"] = math.max(40, (tonumber(fact.sw) or 1920) / 2 - 230), math.max(40, (tonumber(fact.sh) or 1080) / 4)
    card.open(rows, { id = "polkit", width = 380, keep = asking, field = p.asking and {
        hint = ((p.prompt or ""):gsub("[:%s]+$", "")), secret = p.secret ~= false,
        submit = function(answer) pcall(sys.call, "polkit.answer", answer) return false end,
    } or nil })
    asking = true
end

function M.start()
    local served = pcall(sys.watch, "polkit", function(p)
        if type(p) ~= "table" then return end
        if p.ready == false then log("polkit · another program is this session's password dialog") end
        if p.pending then
            show(p)
        elseif asking then
            asking = false
            if card.id() == "polkit" then card.close() end
        end
    end)
    if not served then log("polkit · this system has no polkit to answer for") end
    -- the card was closed without an answer: the program is told it was turned down
    on("card_closed", function() if asking then asking = false pcall(sys.call, "polkit.cancel") end end)
end

return M
