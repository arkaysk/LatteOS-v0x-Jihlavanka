-- What LensShore may change by itself (6B.25, the first level of its AI): each skill names one thing of this computer,
-- reads what it is now and changes it. The AI is told the list (M.prompt) and answers with a ```latte block, a JSON
-- object a line ({"skill": "wifi", "on": false}); typed words reach the same skills without any AI (lens.luau's
-- quick rows). Nothing changes before the user presses the row, which says what changes, from what to what; what was
-- done goes to the journal (journalctl -t latte-lensshore).
local drops = require("lib/engine")
local M = {}

local now = {}                                   -- what each thing is, as last read: M.refresh
local function onoff(b) return b and tr("on") or tr("off") end
local function level(a) local n = tonumber(a.level) return n and n >= 0 and n <= 100 and math.floor(n) or nil end
local function switch(a) return type(a.on) == "boolean" and a.on or nil end
local function named(list, name)                 -- the one whose name holds the name asked for, or is held by it
    name = type(name) == "string" and name:lower() or ""
    if name == "" then return nil end
    for _, d in ipairs(list or {}) do
        local l = d.label:lower()
        if l:find(name, 1, true) or name:find(l, 1, true) then return d end
    end
end
local function cmd(c, args) return function(done) run(c, args, function(_, code) done(code == 0) end) end end

-- `use` is how the AI is to ask for it; `value` the argument checked, nil when it is not one; `row` what the row
-- says and the change it makes; `known` whether this computer has the thing at all (from what was read)
local SKILLS = {
    { id = "wifi", use = '{"skill": "wifi", "on": true|false}', glyph = "wifi", known = function() return now.wifi ~= nil end,
      value = switch, row = function(on) return on and tr("Turn the Wi-Fi on") or tr("Turn the Wi-Fi off"), "Wi-Fi", now.wifi ~= nil and onoff(now.wifi), onoff(on) end,
      run = function(on) return cmd("nmcli", { "radio", "wifi", on and "on" or "off" }) end },
    { id = "bluetooth", use = '{"skill": "bluetooth", "on": true|false}', glyph = "bluetooth", known = function() return now.bt ~= nil end,
      value = switch, row = function(on) return on and tr("Turn Bluetooth on") or tr("Turn Bluetooth off"), "Bluetooth", now.bt ~= nil and onoff(now.bt), onoff(on) end,
      run = function(on) return cmd("bluetoothctl", { "power", on and "on" or "off" }) end },
    { id = "connect", use = '{"skill": "connect", "device": "<a paired Bluetooth device>"}', glyph = "headphones", known = function() return #(now.paired or {}) > 0 end,
      value = function(a) return named(now.paired, a.device) end,
      row = function(d) return (tr("Connect {name}"):gsub("{name}", d.label)), "Bluetooth", nil, d.id end,
      run = function(d) return cmd("bluetoothctl", { "connect", d.id }) end },
    { id = "volume", use = '{"skill": "volume", "level": 0-100}', glyph = "volume", known = function() return now.volume ~= nil end,
      value = level, row = function(n) return (tr("Set the volume to {n} %"):gsub("{n}", n)), tr("Volume"), now.volume and now.volume .. " %", n .. " %" end,
      run = function(n) return cmd("wpctl", { "set-volume", "@DEFAULT_AUDIO_SINK@", tostring(n / 100) }) end },
    { id = "mute", use = '{"skill": "mute", "on": true|false}', glyph = "volume-off", known = function() return now.muted ~= nil end,
      value = switch, row = function(on) return on and tr("Mute the sound") or tr("Unmute the sound"), tr("Sound"), now.muted ~= nil and (now.muted and tr("muted") or tr("playing")), on and tr("muted") or tr("playing") end,
      run = function(on) return cmd("wpctl", { "set-mute", "@DEFAULT_AUDIO_SINK@", on and "1" or "0" }) end },
    { id = "output", use = '{"skill": "output", "device": "<a sound output>"}', glyph = "device-speaker", known = function() return #(now.outputs or {}) > 1 end,
      value = function(a) return named(now.outputs, a.device) end,
      row = function(d) return (tr("Play the sound through {name}"):gsub("{name}", d.label)), tr("Sound output"), now.output, d.label end,
      run = function(d) return cmd("pactl", { "set-default-sink", d.id }) end },
    { id = "brightness", use = '{"skill": "brightness", "level": 0-100}', glyph = "sun", known = function() return now.light ~= nil end,
      value = level, row = function(n) return (tr("Set the brightness to {n} %"):gsub("{n}", n)), tr("Brightness"), now.light and now.light .. " %", n .. " %" end,
      run = function(n) return cmd("brightnessctl", { "set", n .. "%" }) end },
    { id = "quiet", use = '{"skill": "quiet", "on": true|false} (do not disturb)', glyph = "bell-off", known = function() return true end,
      value = switch, row = function(on) return on and tr("Do not disturb") or tr("Let notifications through"), tr("Do not disturb"), onoff(drops.settings().quiet == true), onoff(on) end,
      run = function(on) return function(done) drops.set("quiet", on) done(true) end end },
}
local BY = {}
for _, s in ipairs(SKILLS) do BY[s.id] = s end

-- reads what each thing is now; `done` once all have answered
function M.refresh(done)
    local left = 6
    local function one() left -= 1 if left == 0 and done then done() end end
    run("nmcli", { "radio", "wifi" }, function(out) local s = (out or ""):match("%a+")
        if s == "enabled" or s == "disabled" then now.wifi = s == "enabled" else now.wifi = nil end
        one()
    end)
    run("bluetoothctl", { "--timeout", "2", "show" }, function(out)
        local p = (out or ""):match("Powered: (%a+)")
        if p then now.bt = p == "yes" else now.bt = nil end
        one()
    end)
    run("bluetoothctl", { "--timeout", "2", "devices", "Paired" }, function(out)
        now.paired = {}
        for mac, name in (out or ""):gmatch("Device (%S+) ([^\n]+)") do now.paired[#now.paired + 1] = { id = mac, label = name } end
        one()
    end)
    run("wpctl", { "get-volume", "@DEFAULT_AUDIO_SINK@" }, function(out)
        local v = (out or ""):match("Volume: ([%d%.]+)")
        now.volume, now.muted = nil, nil
        if v then now.volume, now.muted = math.floor(tonumber(v) * 100 + 0.5), out:find("MUTED", 1, true) ~= nil end
        one()
    end)
    run("brightnessctl", { "-m", "-c", "backlight" }, function(out, code) now.light = code == 0 and tonumber((out or ""):match("^[^,]*,[^,]*,[^,]*,(%d+)%%")) or nil one() end)
    run("latte-settings", { "sound" }, function(out)
        local ok, s = pcall(json.decode, out or "")
        now.outputs, now.output = {}, nil
        for _, o in ipairs(ok and type(s) == "table" and s.outputs or {}) do
            now.outputs[#now.outputs + 1] = { id = o.name, label = o.label or o.name }
            if o.default then now.output = o.label or o.name end
        end
        one()
    end)
end

-- the row for a skill and its argument, nil when the argument is not one it takes; pressing it is the confirmation
function M.row(id, a)
    local s = BY[id]
    local v = s and s.value(type(a) == "table" and a or {})
    if v == nil then return nil end
    local label, what, from, to = s.row(v)
    return { label = label, glyph = s.glyph, hint = tr("Do it now"),
             line2 = what .. ": " .. (from and from ~= to and (from .. " → ") or "") .. to,
             run = function()
                 s.run(v)(function(ok)
                     run("logger", { "-t", "latte-lensshore", id .. " " .. json.encode(a) .. (ok and " done" or " failed") }, nil)
                     if not ok then run("notify-send", { "-a", "LatteOS", label, tr("It did not work") }, nil) end
                     M.refresh()
                 end)
             end }
end

-- what the AI is told: the skills this computer has, and the names it may use for devices
function M.prompt()
    local lines = { "LatteOS can change these things on this computer for the user. When the user asks for one of them, "
        .. "do not explain how to do it and do not say you cannot: say in one short sentence what you will change and add a "
        .. "block ```latte with one JSON object a line (this block is the one exception to plain text); the user confirms "
        .. "it with a click. Ask only for what the user asked for." }
    for _, s in ipairs(SKILLS) do if s.known() then lines[#lines + 1] = s.use end end
    local function names(list) local t = {} for _, d in ipairs(list or {}) do t[#t + 1] = d.label end return table.concat(t, ", ") end
    if #(now.paired or {}) > 0 then lines[#lines + 1] = "Paired Bluetooth devices: " .. names(now.paired) end
    if #(now.outputs or {}) > 1 then lines[#lines + 1] = "Sound outputs: " .. names(now.outputs) end
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
