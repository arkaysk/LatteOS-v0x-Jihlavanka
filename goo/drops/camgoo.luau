-- CamGoo: webcams. A press opens its card with the picture of a camera now (bin/latte-cam fetches it), which one
-- and when it was taken; the sides of the picture go to the one before and the next, the row under it to any of
-- them, and the foot to their list in the Settings (Drops › Webcams), where the user adds their own. While the card
-- is open the picture is fetched again every minute. The right button goes to the next camera.
local card = require("lib/card")
local open = require("lib/open")
local icons = require("lib/icons")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

-- until the user has a list of their own: cameras that publish their picture of now at a fixed address
local DEFAULT = {
    { name = N("Innsbruck"), url = "https://www.foto-webcam.eu/webcam/innsbruck/current/1200.jpg" },
    { name = N("Zugspitze"), url = "https://www.foto-webcam.eu/webcam/zugspitze/current/1200.jpg" },
    { name = N("Salzburg"), url = "https://www.foto-webcam.eu/webcam/salzburg/current/1200.jpg" },
    { name = N("Vienna"), url = "https://www.foto-webcam.eu/webcam/wien/current/1200.jpg" },
}
local at = 1
local shots = {}                             -- url → { path, time } of the last picture
local asking = {}                            -- url → true while it is being fetched
local refresh

local function cams()
    local ok, saved = pcall(sys.ask, "files.read", "cams.json", "json")
    if ok and type(saved) == "table" and #saved > 0 then return saved end
    return DEFAULT
end
local function name_of(c) return tr(c.name or "") end

local function fill()
    local list = cams()
    if at > #list then at = 1 end
    local c = list[at]
    text.ic_cam, text.ic_left, text.ic_right, text.ic_cog = icons["camera"], icons["chevron-left"], icons["chevron-right"], icons["settings"]
    text.cam_foot = tr("Webcams in Settings")
    local chips = {}
    for i, x in ipairs(list) do if i <= 6 then chips[i] = { name = name_of(x), on = i == at } end end
    model.camlist = chips
    if not c then
        text.cam_name, text.cam_time, text.cam_note, fact.cam_has = tr("No webcams"), "", tr("Add some in Settings"), 0
        return
    end
    text.cam_name = name_of(c)
    local shot = shots[c.url]
    fact.cam_has = shot and 1 or 0
    if shot then text.cam_path, text.cam_time = shot.path, tr("taken at") .. " " .. shot.time end
    if not shot then text.cam_time, text.cam_note = "", asking[c.url] == "failed" and tr("The camera did not answer") or tr("Loading…") end
end

local function fetch(c)
    if not c or asking[c.url] == true then return end
    asking[c.url] = true
    run("latte-cam", { "fetch", c.url }, function(out, code)
        local path = (out or ""):match("^%s*(%S+)")
        if code == 0 and path then shots[c.url], asking[c.url] = { path = path, time = os.date("%H:%M") }, nil
        else asking[c.url] = "failed" end
        if card.id() == "cam" then fill() end
    end)
end

local function open_card(d, keep)
    card.open({}, { owner = d, id = "cam", custom = "cam", width = 560, min_height = 534, split = 470, pane = 1, keep = keep })
    fill()
    fetch(cams()[at])
    if not refresh then
        refresh = every(60000, function()
            if card.id() ~= "cam" then cancel(refresh) refresh = nil return end
            fetch(cams()[at])
        end)
    end
end
local function step(dir)
    local n = #cams()
    if n == 0 then return end
    at = (at - 1 + dir) % n + 1
    fill()
    fetch(cams()[at])
end

return {
    id = "camgoo", name = "CamGoo", glyph = "camera", nature = "calm", size = 21, seat = 17, swell = 0.1,
    home = { edge = 0, at = 0.86 }, pull = 0.25, reach = 130,
    about = function() return tr("left: webcams · right: the next camera") end,
    start = function(d)
        on("cam_pick", function(i) at = (tonumber(i) or 0) + 1 fill() fetch(cams()[at]) end)
        on("cam_step", function(v) step(v == 1 and 1 or -1) end)
        on("cam_settings", function() card.close() after(80, function() open.settings("camgoo") end) end)
    end,
    click = function(d) if card.id() == "cam" then card.close() else open_card(d) end end,
    right = function(d) if card.id() == "cam" then step(1) else open_card(d) end end,
}
