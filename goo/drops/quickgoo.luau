-- QuickGoo: what is changed often and at once: the network, the sound, Bluetooth, the screen's brightness, and
-- the programs that run in the background. Where Windows has the icons of the network and the volume beside
-- its clock, and the quick settings behind them (Win+A).
-- The drop shows the network it is on. A press opens the card: Wi-Fi and Bluetooth on and off, the volume and
-- the brightness as sliders, then the networks, the devices and the speakers each on a card of their own, and
-- the background programs as tiles. The wheel on the drop is the volume, the right button mutes; whenever the
-- volume changes, from here or from a key, the drop shows it for a moment as a ring.
-- All of it comes from pleamar's services, which talk to NetworkManager, PipeWire and BlueZ themselves.
local card = require("lib/card")
-- N marks a text for the translation table (tests/check.sh looks for it); tr() translates it where it is shown.
local function N(s) return s end

local audio, light, net, blue, tray = {}, {}, {}, {}, {}
local has_wifi = false                       -- the machine has a Wi-Fi adapter: one that is switched off still counts
local showing, face_timer = nil, nil         -- which card of its own is open, to keep it up to date
local open_main, open_networks, open_devices, open_sound

local function call(what, ...) local ok, err = pcall(sys.call, what, ...) if not ok then log("quickgoo · " .. what .. ": " .. tostring(err)) end end
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

local function show_face(d)
    if face_timer then return end                -- the ring is on it
    d:set({ kind = "icon", glyph = net_glyph() })
end
-- the volume has changed: the drop is a ring filled that far, for a moment
local function show_volume(d)
    if face_timer then cancel(face_timer) end
    d:set({ kind = "ring", glyph = volume_glyph(), value = audio.muted and 0 or (audio.volume or 0) })
    if fact.tip_k == d.k then d:tip(tr("Volume") .. " " .. (audio.muted and tr("off") or percent(audio.volume))) end     -- its tooltip, if it is up
    face_timer = after(1500, function() face_timer = nil show_face(d) end)
end
local function refresh(d)
    if card.id() ~= "quick" then return end
    if showing == "networks" then open_networks(d, true) elseif showing == "devices" then open_devices(d, true)
    elseif showing == "sound" then open_sound(d, true) else open_main(d, true) end
end
local function back(d) return { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_main(d) end } end

-- ── the networks in range ────────────────────────────────────────────────────────────────────────────────────
local WHY = { password = N("Wrong password"), timeout = N("The network did not answer"), unsupported = N("This kind of network is not supported"),
              busy = N("Another connection is being made"), failed = N("It did not connect") }
local function ask_password(d, ssid)
    showing = "password"
    card.open({ back(d), { label = ssid, glyph = "lock", quiet = true, line = true } },
              { owner = d, id = "quick", width = 320, field = { hint = tr("Password"), secret = true, submit = function(pw)
                  call("network.connect", ssid, pw)
                  open_networks(d)
                  return false
              end } })
end
open_networks = function(d, keep)
    showing = "networks"
    local rows = { back(d) }
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
                else ask_password(d, n.ssid) end
            end,
            right = function()
                if not n.known then return end
                card.open({ { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_networks(d) end },
                            { label = tr("Forget this network"), glyph = "trash", danger = true, line = true, keep = true,
                              run = function() call("network.forget", n.ssid) open_networks(d) end } }, { owner = d, id = "quick", width = 320 })
                showing = "forget"
            end,
        }
    end
    if net.wifi and #(net.networks or {}) == 0 then rows[#rows + 1] = { label = tr("Looking for networks…"), glyph = "wifi-1", quiet = true, line = true } end
    card.open(rows, { owner = d, id = "quick", width = 320, keep = keep })
    if not keep and net.wifi then call("network.scan") end
end

-- ── Bluetooth devices ────────────────────────────────────────────────────────────────────────────────────────
open_devices = function(d, keep)
    showing = "devices"
    local rows = { back(d),
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
                card.open({ { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_devices(d) end },
                            { label = tr("Forget this device"), glyph = "trash", danger = true, line = true, keep = true,
                              run = function() call("bluetooth.forget", dev.address) open_devices(d) end } }, { owner = d, id = "quick", width = 320 })
                showing = "forget"
            end,
        }
    end
    if blue.powered and #(blue.devices or {}) == 0 then rows[#rows + 1] = { label = tr("Looking for devices…"), glyph = "bluetooth", quiet = true, line = true } end
    card.open(rows, { owner = d, id = "quick", width = 320, keep = keep })
    if not keep and blue.powered then call("bluetooth.scan", true) end
end

-- ── where the sound goes and comes from ──────────────────────────────────────────────────────────────────────
open_sound = function(d, keep)
    showing = "sound"
    local rows = { back(d), { head = true, label = tr("OUTPUT"), line = true } }
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
    card.open(rows, { owner = d, id = "quick", width = 340, keep = keep })
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
local function open_menu(d, t)
    local ok, items = pcall(sys.ask, "tray.menu", t.key)
    local rows = { back(d), { head = true, label = t.title or t.id or "", line = true } }
    for _, r in ipairs(ok and menu_rows(t.key, items) or {}) do rows[#rows + 1] = r end
    showing = "menu"
    card.open(rows, { owner = d, id = "quick", width = 320 })
end

-- ── the card ─────────────────────────────────────────────────────────────────────────────────────────────────
open_main = function(d, keep)
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
    if audio.volume ~= nil then
        rows[#rows + 1] = { slide = true, glyph = volume_glyph(), label = tr("Volume"), value = audio.volume, off = audio.muted == true, hint = percent(audio.volume),
                            run = function() call("audio.mute") end, set = function(v) call("audio.volume", v) end, wheel = function(dir) call("audio.step", dir * 0.05) end }
    end
    if light.present then
        rows[#rows + 1] = { slide = true, glyph = "brightness-up", label = tr("Brightness"), value = light.level or 0, hint = percent(light.level),
                            set = function(v) call("brightness.level", math.max(0.02, v)) end,
                            wheel = function(dir) call("brightness.level", math.clamp((light.level or 0) + dir * 0.05, 0.02, 1)) end }
    end
    rows[#rows + 1] = { label = tr("Network"), glyph = net_glyph(), line = #rows > 0, keep = true, more = true, run = function() open_networks(d) end,
                        line2 = net.online and ((net.name or "") ~= "" and net.name or tr("Wired network")) or tr("Offline") }
    if blue.present then
        local names = connected()
        rows[#rows + 1] = { label = "Bluetooth", glyph = "bluetooth", keep = true, more = true, run = function() open_devices(d) end,
                            line2 = not blue.powered and tr("off") or (#names > 0 and table.concat(names, ", ") or tr("no device connected")) }
    end
    if audio.volume ~= nil then
        rows[#rows + 1] = { label = tr("Sound"), glyph = "device-speaker", keep = true, more = true, line2 = output_name(), run = function() open_sound(d) end }
    end
    if #tray > 0 then
        local tiles = {}
        for i, t in ipairs(tray) do
            if i > 12 then break end
            tiles[#tiles + 1] = { label = t.title ~= "" and t.title or t.id or "", icon = t.icon or "", glyph = "apps", run = function() call("tray.activate", t.key) end,
                                  right = function() open_menu(d, t) end }
        end
        rows[#rows + 1] = { head = true, label = tr("IN THE BACKGROUND"), line = true }
        rows[#rows + 1] = { tiles = tiles, per = 4 }
    end
    card.open(rows, { owner = d, id = "quick", width = 320, keep = keep })
end

return {
    id = "quickgoo", name = "QuickGoo", glyph = "wifi-off", nature = "calm", size = 24, seat = 16, swell = 0.1,
    home = { edge = 0, at = 0.86 }, pull = 0.25, reach = 130, zoomable = false,
    about = function()
        local where = net.online and ((net.name or "") ~= "" and net.name or tr("Wired network")) or tr("Offline")
        local sound = audio.volume ~= nil and (" · " .. tr("Volume") .. " " .. (audio.muted and tr("off") or percent(audio.volume))) or ""
        return where .. sound .. " · " .. tr("left: quick settings · wheel: volume · right: mute")
    end,
    start = function(d)
        local function watch(name, keep)
            pcall(sys.watch, name, function(v)
                keep(v)
                refresh(d)
            end)
        end
        watch("network", function(v)
            net = type(v) == "table" and v or {}
            if net.wifi or net.kind == "wifi" then has_wifi = true end
            show_face(d)
        end)
        -- An adapter whose radio is off reports nothing; NetworkManager knows it is there.
        run("nmcli", { "-t", "-f", "TYPE", "device" }, function(out) if (out or ""):find("wifi", 1, true) then has_wifi = true refresh(d) end end)
        watch("bluetooth", function(v) blue = type(v) == "table" and v or {} end)
        watch("brightness", function(v) light = type(v) == "table" and v or {} end)
        watch("tray", function(v) tray = type(v) == "table" and v or {} end)
        local first = true
        watch("audio", function(v)
            local was, mute = audio.volume, audio.muted
            audio = type(v) == "table" and v or {}
            -- the first report is how things are, not a change; with the card open the slider already shows it
            if not first and card.id() ~= "quick" and (audio.volume ~= was or audio.muted ~= mute) then show_volume(d) end
            first = false
        end)
        on("quick_toggle", function() if card.id() == "quick" then card.close() else open_main(d) end end)
    end,
    click = function(d) if card.id() == "quick" then card.close() else open_main(d) end end,
    right = function() call("audio.mute") end,
    wheel = function(_, dir) call("audio.step", dir * 0.05) end,
}
