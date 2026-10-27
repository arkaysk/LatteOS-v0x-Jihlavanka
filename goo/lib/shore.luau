-- The shore's logic (parts/shore.plm): the hard corner of the screen. What Windows keeps beside its clock: the
-- programs that run in the background, the network, the volume, and on a laptop the battery.
-- Its arrow brings out the dashboard above it, low and wide along the bottom: on the left what is switched and
-- set (Wi-Fi and Bluetooth on and off, the volume and the brightness as sliders; the networks, the devices and
-- the speakers each on a page of their own), on the right what is going on (what plays, with its buttons, and
-- what was copied lately: cliphist keeps that, a press copies it again). The calendar, the weather and the
-- notifications are ClockGoo's and stay there.
-- A background program's icon is pressed as in any tray; its right button shows the program's own menu.
-- The wheel on the volume changes it, the right button mutes; a change shows for a moment as a ring.
-- All of it comes from pleamar's services, which talk to NetworkManager, PipeWire and BlueZ themselves.
local E = require("lib/engine")
local card = require("lib/card")
local icons = require("lib/icons")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local audio, light, net, blue, tray, media = {}, {}, {}, {}, {}, {}
local has_wifi = false                       -- the machine has a Wi-Fi adapter: one that is switched off still counts
local showing = nil                          -- which page of the panel is out, to keep it up to date
local clips = {}                             -- what was copied lately: { id, text }
local open_main, open_networks, open_devices, open_sound

local function call(what, ...) local ok, err = pcall(sys.call, what, ...) if not ok then log("shore · " .. what .. ": " .. tostring(err)) end end
local function percent(v) return math.floor((tonumber(v) or 0) * 100 + 0.5) .. " %" end
local function wifi_glyph(strength)
    strength = tonumber(strength) or 0
    return strength >= 67 and "wifi" or (strength >= 34 and "wifi-2" or "wifi-1")
end
local function net_glyph()
    if not net.online then return "wifi-off" end
    return net.kind == "wired" and "network" or wifi_glyph(net.strength)
end
local function volume_glyph() return audio.muted and "volume-off" or ((audio.volume or 0) >= 0.5 and "volume" or "volume-2") end
local function connected()
    local names = {}
    for _, dev in ipairs(blue.devices or {}) do if dev.connected then names[#names + 1] = dev.name or dev.address end end
    return names
end
local function output_name()
    for _, o in ipairs(audio.outputs or {}) do if o.default then return o.name or "" end end
    return ""
end

-- ── what stands on the shore ─────────────────────────────────────────────────────────────────────────────────
local HEIGHT = 46                            -- the plate's, as the scene draws it
local LENS = 720                             -- with LensShore's line the plate is as long as the launcher's card at least (600 × 1.2, lib/card.luau)
local shown_bg = {}                          -- the background programs on it, in the order they are drawn
local has_battery, battery = false, {}
local function battery_glyph()
    if battery.charging then return "battery-charging" end
    local p = tonumber(battery.percent) or 0
    return p >= 75 and "battery-4" or (p >= 50 and "battery-3" or (p >= 25 and "battery-2" or "battery-1"))
end
local function show_signs()
    text.shore_net, text.shore_vol = icons[net_glyph()] or "", icons[volume_glyph()] or ""
    text.shore_ask = tr("Search or ask…")
    text.shore_bat = has_battery and (icons[battery_glyph()] or "") or ""
    text.shore_arrow = icons[fact.shore_open and "chevron-down" or "chevron-up"] or ""
end
-- how long the plate is: the arrow, the programs, the signs
local function lay_out()
    local list = {}
    shown_bg = {}
    for i, t in ipairs(tray) do
        if i > 10 then break end
        shown_bg[i] = t
        list[i] = { icon = t.icon or "", has_icon = (t.icon or "") ~= "", glyph = icons["apps"], title = (t.title or "") ~= "" and t.title or (t.id or "") }
    end
    model.bg = list
    local signs = has_battery and 3 or 2
    fact.shore_signs = signs
    local rest = 65 + 30 * #list + 34 * signs
    fact.shore_lens = fact.lens_shore and math.max(260, LENS - rest) or 0
    fact.shore_w = fact.shore_lens + rest
    E.shore(fact.shore_w, HEIGHT)
    show_signs()
end
-- A page of the panel: a card that stands on the shore and reaches the top of the screen.
local function panel(rows, opts)
    opts = opts or {}
    local w, h = tonumber(fact.sw) or 1920, tonumber(fact.sh) or 1080
    fact["tap.x"], fact["tap.y"] = w - 6, h - HEIGHT - 4
    opts.id, opts.owner, opts.dock = "shore", nil, tonumber(fact.shore_w) or 0
    opts.width = opts.width or 320
    card.open(rows, opts)
    if not fact.shore_open then fact.shore_open = true show_signs() end
end
-- cliphist lists what it kept, the newest first: "id<TAB>the text, on one line"
local function read_clips(then_do)
    run("cliphist", { "list" }, function(out, code)
        clips = {}
        for id, what in (code == 0 and out or ""):gmatch("(%d+)\t([^\n]*)") do
            if #clips >= 8 then break end
            what = what:gsub("%s+", " ")
            local ok, cut = pcall(utf8.offset, what, 61)         -- sixty letters, not sixty bytes
            clips[#clips + 1] = { id = id, text = (ok and cut) and (what:sub(1, cut - 1) .. "…") or what }
        end
        then_do()
    end)
end
local function refresh()
    if card.id() ~= "shore" then return end
    if showing == "networks" then open_networks(true) elseif showing == "devices" then open_devices(true)
    elseif showing == "sound" then open_sound(true) else open_main(true) end
end
local function back() return { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_main() end } end

-- ── the networks in range ────────────────────────────────────────────────────────────────────────────────────
local WHY = { password = N("Wrong password"), timeout = N("The network did not answer"), unsupported = N("This kind of network is not supported"),
              busy = N("Another connection is being made"), failed = N("It did not connect") }
local function ask_password(ssid)
    showing = "password"
    panel({ back(), { label = ssid, glyph = "lock", quiet = true, line = true } },
          { width = 320, field = { hint = tr("Password"), secret = true, submit = function(pw)
              call("network.connect", ssid, pw)
              open_networks()
              return false
          end } })
end
open_networks = function(keep)
    showing = "networks"
    local rows = { back() }
    if has_wifi then
        rows[#rows + 1] = { label = "Wi-Fi", glyph = net.wifi and "wifi" or "wifi-off", on = net.wifi == true, hint = tr(net.wifi and N("on") or N("off")), keep = true, line = true,
                            run = function() call("network.wifi", not net.wifi) end }
    end
    if net.kind == "wired" and net.online then rows[#rows + 1] = { label = tr("Wired network"), glyph = "network", hint = tr("connected"), quiet = true } end
    if (net.error or "none") ~= "none" then rows[#rows + 1] = { label = tr(WHY[net.error] or WHY.failed), glyph = "alert-triangle", danger = true, quiet = true } end
    for i, n in ipairs(net.networks or {}) do
        if i > 12 then break end
        rows[#rows + 1] = {
            label = n.ssid or "", glyph = wifi_glyph(n.strength), on = n.active == true, line = i == 1, keep = true,
            hint = n.active and tr("connected") or (n.known and tr("saved") or (n.secure and tr("secured") or "")),
            run = function()
                if n.active then call("network.disconnect")
                elseif n.known or not n.secure then call("network.connect", n.ssid)
                else ask_password(n.ssid) end
            end,
            right = function()
                if not n.known then return end
                panel({ { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_networks() end },
                            { label = tr("Forget this network"), glyph = "trash", danger = true, line = true, keep = true,
                              run = function() call("network.forget", n.ssid) open_networks() end } }, { width = 320 })
                showing = "forget"
            end,
        }
    end
    if net.wifi and #(net.networks or {}) == 0 then rows[#rows + 1] = { label = tr("Looking for networks…"), glyph = "wifi-1", quiet = true, line = true } end
    panel(rows, { width = 320, keep = keep })
    if not keep and net.wifi then call("network.scan") end
end

-- ── Bluetooth devices ────────────────────────────────────────────────────────────────────────────────────────
open_devices = function(keep)
    showing = "devices"
    local rows = { back(),
                   { label = "Bluetooth", glyph = blue.powered and "bluetooth" or "bluetooth-off", on = blue.powered == true, hint = tr(blue.powered and N("on") or N("off")),
                     keep = true, line = true, run = function() call("bluetooth.power", not blue.powered) end } }
    for i, dev in ipairs(blue.devices or {}) do
        if i > 12 then break end
        local battery = (tonumber(dev.battery) or -1) >= 0 and ("  ·  " .. percent(dev.battery)) or ""
        rows[#rows + 1] = {
            label = dev.name or dev.address or "", glyph = "bluetooth", on = dev.connected == true, line = i == 1, keep = true,
            hint = (dev.connected and tr("connected") or (dev.paired and tr("paired") or "")) .. battery,
            run = function() call(dev.connected and "bluetooth.disconnect" or "bluetooth.connect", dev.address) end,
            right = function()
                if not dev.paired then return end
                panel({ { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_devices() end },
                            { label = tr("Forget this device"), glyph = "trash", danger = true, line = true, keep = true,
                              run = function() call("bluetooth.forget", dev.address) open_devices() end } }, { width = 320 })
                showing = "forget"
            end,
        }
    end
    if blue.powered and #(blue.devices or {}) == 0 then rows[#rows + 1] = { label = tr("Looking for devices…"), glyph = "bluetooth", quiet = true, line = true } end
    panel(rows, { width = 320, keep = keep })
    if not keep and blue.powered then call("bluetooth.scan", true) end
end

-- ── where the sound goes and comes from ──────────────────────────────────────────────────────────────────────
open_sound = function(keep)
    showing = "sound"
    local rows = { back(), { head = true, label = tr("OUTPUT"), line = true } }
    for i, o in ipairs(audio.outputs or {}) do
        if i > 6 then break end
        rows[#rows + 1] = { label = o.name or "", glyph = "device-speaker", on = o.default == true, keep = true, run = function() call("audio.default", o.id) end }
    end
    rows[#rows + 1] = { head = true, label = tr("INPUT"), line = true }
    rows[#rows + 1] = { slide = true, glyph = audio.input_muted and "microphone-off" or "microphone", label = tr("Microphone"), value = audio.input or 0,
                        off = audio.input_muted == true, hint = percent(audio.input), run = function() call("audio.input_mute") end,
                        set = function(v) call("audio.input", v) end, wheel = function(dir) call("audio.input", math.clamp((audio.input or 0) + dir * 0.05, 0, 1)) end }
    for i, o in ipairs(audio.inputs or {}) do
        if i > 4 then break end
        rows[#rows + 1] = { label = o.name or "", glyph = "microphone", on = o.default == true, keep = true, run = function() call("audio.default", o.id) end }
    end
    panel(rows, { width = 340, keep = keep })
end

-- ── a background program's own menu ──────────────────────────────────────────────────────────────────────────
local function menu_rows(key, items)
    local rows = {}
    for _, it in ipairs(items or {}) do
        if it.separator then
            if #rows > 0 then rows[#rows].after = true end
        elseif (it.label or "") ~= "" then
            local kids = type(it.children) == "table" and #it.children > 0 and menu_rows(key, it.children) or nil
            rows[#rows + 1] = { label = (it.label:gsub("_", "")), on = it.checked == true, off = it.enabled == false, sub = kids,
                                run = not kids and function() call("tray.menu_click", key, it.id) end or nil }
        end
    end
    for i = 2, #rows do if rows[i - 1].after then rows[i].line = true end end
    return rows
end
local function open_menu(t)
    local ok, items = pcall(sys.ask, "tray.menu", t.key)
    local rows = { back(), { head = true, label = t.title or t.id or "", line = true } }
    for _, r in ipairs(ok and menu_rows(t.key, items) or {}) do rows[#rows + 1] = r end
    showing = "menu"
    panel(rows, { width = 320 })
end

-- ── the card ─────────────────────────────────────────────────────────────────────────────────────────────────
open_main = function(keep)
    showing = "main"
    local rows, pills = {}, {}
    if has_wifi then
        pills[#pills + 1] = { label = "Wi-Fi", glyph = net.wifi and "wifi" or "wifi-off", on = net.wifi == true, keep = true, run = function() call("network.wifi", not net.wifi) end }
    end
    if blue.present then
        pills[#pills + 1] = { label = "Bluetooth", glyph = blue.powered and "bluetooth" or "bluetooth-off", on = blue.powered == true, keep = true,
                              run = function() call("bluetooth.power", not blue.powered) end }
    end
    if #pills > 0 then rows[#rows + 1] = { pills = pills } end
    if audio.volume ~= nil or light.present then rows[#rows + 1] = { head = true, label = tr("SOUND AND LIGHT") } end
    if audio.volume ~= nil then
        rows[#rows + 1] = { slide = true, glyph = volume_glyph(), label = tr("Volume"), value = audio.volume, off = audio.muted == true, hint = percent(audio.volume),
                            run = function() call("audio.mute") end, set = function(v) call("audio.volume", v) end, wheel = function(dir) call("audio.step", dir * 0.05) end }
    end
    if light.present then
        rows[#rows + 1] = { slide = true, glyph = "brightness-up", label = tr("Brightness"), value = light.level or 0, hint = percent(light.level),
                            set = function(v) call("brightness.level", math.max(0.02, v)) end,
                            wheel = function(dir) call("brightness.level", math.clamp((light.level or 0) + dir * 0.05, 0.02, 1)) end }
    end
    rows[#rows + 1] = { head = true, label = tr("CONNECTIONS") }
    rows[#rows + 1] = { label = tr("Network"), glyph = net_glyph(), keep = true, more = true, run = function() open_networks() end,
                        line2 = net.online and ((net.name or "") ~= "" and net.name or tr("Wired network")) or tr("Offline") }
    if blue.present then
        local names = connected()
        rows[#rows + 1] = { label = "Bluetooth", glyph = "bluetooth", keep = true, more = true, run = function() open_devices() end,
                            line2 = not blue.powered and tr("off") or (#names > 0 and table.concat(names, ", ") or tr("no device connected")) }
    end
    if audio.volume ~= nil then
        rows[#rows + 1] = { label = tr("Sound"), glyph = "device-speaker", keep = true, more = true, line2 = output_name(), run = function() open_sound() end }
    end
    -- the right half: what is going on
    local right = {}
    if (media.title or "") ~= "" or (media.player or "") ~= "" then
        right[#right + 1] = { head = true, label = tr("NOW PLAYING") }
        right[#right + 1] = { profile = true, icon = (media.art or "") ~= "" and media.art or nil, glyph = "music", quiet = true,
                              label = (media.title or "") ~= "" and media.title or (media.player or ""), line2 = media.artist or "" }
        right[#right + 1] = { pills = {
            { glyph = "player-skip-back", label = tr("Previous"), keep = true, run = function() call("media.previous") end },
            { glyph = media.playing and "player-pause" or "player-play", label = media.playing and tr("Pause") or tr("Play"), on = media.playing == true, keep = true, run = function() call("media.toggle") end },
            { glyph = "player-skip-forward", label = tr("Next"), keep = true, run = function() call("media.next") end },
        } }
    end
    -- what was copied lately: a press copies it again
    right[#right + 1] = { head = true, label = tr("CLIPBOARD"), line = #right > 0 }
    if #clips == 0 then right[#right + 1] = { label = tr("Nothing was copied yet"), glyph = "clipboard", quiet = true } end
    for i, c in ipairs(clips) do
        if i > 6 then break end
        right[#right + 1] = { label = c.text, glyph = "clipboard", run = function() run("sh", { "-c", "cliphist decode " .. c.id .. " | wl-copy" }, nil, { output = false }) end }
    end
    if #clips > 0 then
        right[#right + 1] = { label = tr("Forget what was copied"), glyph = "trash", danger = true, keep = true,
                              run = function() run("cliphist", { "wipe" }, function() clips = {} open_main(true) end) end }
    end
    for _, r in ipairs(right) do r.col = 2 rows[#rows + 1] = r end
    panel(rows, { width = 340, width2 = 340, keep = keep, tiles = true })
end

-- what the pointer rests on: 0 the arrow, 1 the network, 2 the volume, 3 the battery, 10… the programs
local function tip_for(what)
    if what == 0 then return fact.shore_open and tr("Close the panel") or tr("Quick settings and the clipboard") end
    if what == 1 then return net.online and ((net.name or "") ~= "" and net.name or tr("Wired network")) or tr("Offline") end
    if what == 2 then return tr("Volume") .. " " .. (audio.muted and tr("off") or percent(audio.volume)) .. " · " .. tr("wheel: volume · right: mute") end
    if what == 3 then return tr("Battery") .. " " .. math.floor(tonumber(battery.percent) or 0) .. " %" end
    local t = shown_bg[what - 9]
    return t and ((t.title or "") ~= "" and t.title or (t.id or "")) or ""
end

local M = {}
function M.toggle()
    if card.id() == "shore" then card.close() else read_clips(function() open_main() end) end
end
function M.start()
    local function watch(name, keep)
        pcall(sys.watch, name, function(v)
            keep(v)
            refresh()
        end)
    end
    watch("network", function(v)
        net = type(v) == "table" and v or {}
        if net.wifi or net.kind == "wifi" then has_wifi = true end
        show_signs()
    end)
    -- An adapter whose radio is off reports nothing; NetworkManager knows it is there.
    run("nmcli", { "-t", "-f", "TYPE", "device" }, function(out) if (out or ""):find("wifi", 1, true) then has_wifi = true refresh() end end)
    watch("bluetooth", function(v) blue = type(v) == "table" and v or {} end)
    watch("media", function(v) media = type(v) == "table" and v or {} end)
    watch("brightness", function(v) light = type(v) == "table" and v or {} end)
    watch("tray", function(v) tray = type(v) == "table" and v or {} lay_out() end)
    watch("battery", function(v)
        battery = type(v) == "table" and v or {}
        local there = battery.present == true
        if there ~= has_battery then has_battery = there lay_out() else show_signs() end
    end)
    local first = true
    watch("audio", function(v)
        local was, mute = audio.volume, audio.muted
        audio = type(v) == "table" and v or {}
        show_signs()
        -- the first report is how things are, not a change: after it, a change shows as a ring round the sign
        if not first and (audio.volume ~= was or audio.muted ~= mute) then
            fact.shore_level = audio.muted and 0 or (audio.volume or 0)
            fact.shore_rang += 1
            if fact.tip_k == 302 then text.tip = tip_for(2) end
        end
        first = false
    end)
    on("shore_more", M.toggle)
    on("fact:lens_shore", lay_out)
    on("quick_toggle", M.toggle)
    on("shore_sign", function(s)
        if s == 0 then read_clips(function() open_networks() end) else M.toggle() end
    end)
    on("shore_sign_right", function(s) if s == 1 then call("audio.mute") end end)
    on("shore_wheel", function(v) if (v or 0) // 2 == 1 then call("audio.step", ((v or 0) % 2 == 1 and 1 or -1) * 0.05) end end)
    on("shore_bg", function(j) local t = shown_bg[(j or 0) + 1] if t then call("tray.activate", t.key) end end)
    on("shore_bg_right", function(j) local t = shown_bg[(j or 0) + 1] if t then open_menu(t) end end)
    on("shore_hover", function(what) text.tip = tip_for(what or 0) end)
    -- the arrow turns back when the panel goes, whoever closed it
    card.watch(function(id) if fact.shore_open and id ~= "shore" then fact.shore_open = false show_signs() end end)
    lay_out()
end

return M
