-- MediaGoo: what is playing. It is on the desktop only while some player is there, and beats while it plays.
-- A press opens its card (the cover, the title, back · play · next, the volume, and with several players which
-- one); the right button plays and pauses, the wheel is the volume.
local card = require("lib/card")
local open = require("lib/open")

local media, audio = {}, {}
local function call(what, ...) local ok, err = pcall(sys.call, what, ...) if not ok then log("mediagoo · " .. what .. ": " .. tostring(err)) end end
local function percent(v) return math.floor((tonumber(v) or 0) * 100 + 0.5) .. " %" end
local function title() return (media.title or "") ~= "" and media.title or (media.player or "") end
local function art()
    local a = media.art or ""
    return a:gsub("^file://", "")
end

local function open_card(d, keep)
    local rows = {
        { profile = true, icon = art(), glyph = "music", label = title(), line2 = media.artist or "", quiet = true },
        { pills = {
            { glyph = "player-skip-back", label = tr("Previous"), keep = true, run = function() call("media.previous") end },
            { glyph = media.playing and "player-pause" or "player-play", label = media.playing and tr("Pause") or tr("Play"), on = media.playing == true, keep = true, run = function() call("media.toggle") end },
            { glyph = "player-skip-forward", label = tr("Next"), keep = true, run = function() call("media.next") end },
        } },
    }
    if audio.volume ~= nil then
        rows[#rows + 1] = { slide = true, glyph = audio.muted and "volume-off" or "volume", label = tr("Volume"), value = audio.volume, off = audio.muted == true, hint = percent(audio.volume),
                            run = function() call("audio.mute") end, set = function(v) call("audio.volume", v) end, wheel = function(dir) call("audio.step", dir * 0.05) end }
    end
    local players = type(media.players) == "table" and media.players or {}
    if #players > 1 then
        rows[#rows + 1] = { head = true, label = tr("PLAYERS"), line = true }
        for i, p in ipairs(players) do
            if i > 5 then break end
            rows[#rows + 1] = { label = p.name or p.id or "", glyph = p.playing and "player-play" or "player-pause", on = p.chosen == true, keep = true,
                                run = function() call("media.choose", p.chosen and "" or p.id) end }
        end
    end
    card.open(rows, { owner = d, id = "media", width = 320, keep = keep, foot = { label = tr("Sound settings"), glyph = "volume", run = function() open.settings("sound") end } })
end

return {
    id = "mediagoo", name = "MediaGoo", glyph = "music", nature = "calm", size = 22, seat = 15, swell = 0.1,
    home = { edge = 0, at = 0.72 }, pull = 0.25, reach = 130, zoomable = false,
    about = function()
        local who = (media.artist or "") ~= "" and (" · " .. media.artist) or ""
        return title() .. who .. " · " .. tr("left: player · wheel: volume · right: play or pause")
    end,
    start = function(d)
        d:present(false)
        local shown = ""
        pcall(sys.watch, "media", function(v)
            media = type(v) == "table" and v or {}
            local players = type(media.players) == "table" and media.players or {}
            local there = (media.player or "") ~= "" or #players > 0
            -- the service also says how far the song is, every second: only what the drop and the card show counts
            local now = table.concat({ tostring(there), tostring(media.playing), media.title or "", media.artist or "", media.art or "", media.player or "", #players }, "\1")
            if now == shown then return end
            shown = now
            d:present(there)
            d:fx(media.playing and "beat" or "none", 0.5)
            if card.id() == "media" then if there then open_card(d, true) else card.close() end end
        end)
        pcall(sys.watch, "audio", function(v)
            audio = type(v) == "table" and v or {}
            if card.id() == "media" then open_card(d, true) end
        end)
    end,
    click = function(d) if card.id() == "media" then card.close() else open_card(d) end end,
    right = function() call("media.toggle") end,
    wheel = function(_, dir) call("audio.step", dir * 0.05) end,
}
