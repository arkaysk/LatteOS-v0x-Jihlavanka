-- What LensShore may change by itself (6B.25, the first level of its AI): each skill names one thing of this computer,
-- reads what it is now and changes it. The AI is told the list (M.prompt) and answers with a ```latte block, a JSON
-- object a line ({"skill": "wifi", "on": false}); typed words reach the same skills without any AI (lens.luau's
-- quick rows). Nothing changes before the user presses the row, which says what changes, from what to what; what was
-- done goes to the journal (journalctl -t latte-lensshore). What can lose the user's work (closing an app) asks twice and
-- says what will be lost (ROZHODNUTIA 28. 10.).
-- The skills themselves are bin/latte-skill's (ROADMAP 10B.53): the same ones every AI reaches through bin/latte-mcp.
-- This file asks it what there is and what a row says, draws the row, and does it on the press.
local M = {}

local now, uses = {}, {}                         -- what each thing is, and how the AI asks for each: M.refresh
local rows = {}                                  -- what a row says, by skill and argument: nil not asked yet, false not one
local GLYPH = { wifi = "wifi", bluetooth = "bluetooth", connect = "headphones", volume = "volume", mute = "volume-off",
                output = "device-speaker", brightness = "sun", quiet = "bell-off", nightlight = "sun-low", power = "bolt",
                network = "wifi", open = "app-window", close = "x" }

-- reads what each thing is now; `done` once it has answered
function M.refresh(done)
    run("latte-skill", { "list" }, function(out)
        local ok, t = pcall(json.decode, out or "")
        if ok and type(t) == "table" then now, uses, rows = t.now or {}, t.skills or {}, {} end
        if done then done() end
    end)
end

-- the row for a skill and its argument: nil while latte-skill is asked what it says (`again` draws the card anew when
-- it has answered), false when the argument is not one it takes; pressing it is the confirmation.
-- A risky one is pressed twice: the first press arms it and says what will be lost.
local armed = {}
function M.row(id, a, again)
    a = type(a) == "table" and a or {}
    local args = json.encode(a)
    local key = tostring(id) .. args
    local r = rows[key]
    if r == nil then
        rows[key] = "asking"
        run("latte-skill", { "row", tostring(id), args, "--now", json.encode(now) }, function(out, code)
            local ok, t = pcall(json.decode, out or "")
            rows[key] = code == 0 and ok and type(t) == "table" and t or false
            if again then again() end
        end)
        return nil
    end
    if r == "asking" then return nil end
    if not r then return false end
    local line2 = r.what .. ": " .. (r.from and (r.from .. " → ") or "") .. r.to
    if r.risky and not armed[key] then
        return { label = r.label, glyph = GLYPH[id], hint = tr("Do it now"), line2 = line2, keep = true,
                 run = function() armed[key] = true if again then again() end end }
    end
    return { label = r.risky and tr("Really? Press once more") or r.label, glyph = GLYPH[id], hint = tr("Do it now"),
             line2 = r.risky and r.warn or line2, danger = r.risky,
             run = function()
                 armed[key] = nil
                 run("latte-skill", { "do", id, args, "--now", json.encode(now) }, function(_, code)
                     if code ~= 0 then run("notify-send", { "-a", "LatteOS", r.label, tr("It did not work") }, nil) end
                     M.refresh(again)
                 end)
             end }
end

-- what LensShore's home offers at once (6B.27): the other way of what each switch is now, as buttons; only what this
-- computer has, and nothing that can lose work
function M.suggestions(again)
    local wanted = {
        now.wifi ~= nil and { "wifi", { on = not now.wifi } } or nil,
        { "quiet", { on = now.quiet ~= true } },
        now.night ~= nil and { "nightlight", { on = not now.night } } or nil,
        now.muted ~= nil and { "mute", { on = not now.muted } } or nil,
        now.bt ~= nil and { "bluetooth", { on = not now.bt } } or nil,
        now.profile ~= nil and { "power", { profile = now.profile == "power-saver" and "balanced" or "power-saver" } } or nil,
    }
    local out = {}
    for i = 1, 6 do
        local w = wanted[i]
        local r = w and M.row(w[1], w[2], again)
        if r then out[#out + 1] = { label = r.label, glyph = r.glyph, run = r.run } end
    end
    return out
end

-- what the AI is told: the skills this computer has, and the names it may use for devices
function M.prompt()
    local lines = { "LatteOS can change these things on this computer for the user. When the user asks for one of them, "
        .. "do not explain how to do it and do not say you cannot: say in one short sentence what you will change and add a "
        .. "block ```latte with one JSON object a line (this block is the one exception to plain text); the user confirms "
        .. "it with a click. Ask only for what the user asked for." }
    for _, s in ipairs(uses) do lines[#lines + 1] = s.use end
    local function names(list) local t = {} for _, d in ipairs(list or {}) do t[#t + 1] = d.label end return table.concat(t, ", ") end
    if #(now.paired or {}) > 0 then lines[#lines + 1] = "Paired Bluetooth devices: " .. names(now.paired) end
    if #(now.outputs or {}) > 1 then lines[#lines + 1] = "Sound outputs: " .. names(now.outputs) end
    if #(now.networks or {}) > 0 then lines[#lines + 1] = "Saved Wi-Fi networks: " .. names(now.networks) end
    if #(now.running or {}) > 0 then lines[#lines + 1] = "Running apps: " .. names(now.running) end
    lines[#lines + 1] = "For anything else, answer as usual."
    return table.concat(lines, "\n")
end

-- the skills an answer asks for, from its ```latte blocks
function M.asked(answer)
    local out = {}
    for body in (answer or ""):gmatch("```latte%s*\n(.-)```") do
        for line in body:gmatch("[^\n]+") do
            local ok, a = pcall(json.decode, line)
            if ok and type(a) == "table" and type(a.skill) == "string" then out[#out + 1] = a end
        end
    end
    return out
end

return M
