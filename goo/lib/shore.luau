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
local clipboard = require("lib/clips")
local open = require("lib/open")
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
local shown_bg = {}                          -- the background programs on it, in the order they are drawn
local has_battery, battery = false, {}
local function battery_glyph()
    if battery.charging then return "battery-charging" end
    local p = tonumber(battery.percent) or 0
    return p >= 75 and "battery-4" or (p >= 50 and "battery-3" or (p >= 25 and "battery-2" or "battery-1"))
end
-- the keyboard's layouts, as the session was given them (XKB_DEFAULT_LAYOUT "sk,us"): sk, us
local layouts_cache
local function layout_names()
    if layouts_cache then return layouts_cache end
    local ok, v = pcall(sys.ask, "env", "XKB_DEFAULT_LAYOUT")
    layouts_cache = {}
    if ok and type(v) == "string" then for n in v:gmatch("[^,]+") do layouts_cache[#layouts_cache + 1] = n end end
    return layouts_cache
end
local function show_layout()
    local names = layout_names()
    text.shore_kbname = string.upper(names[(tonumber(fact.kb_layout) or 0) + 1] or "")
end
local function show_signs()
    text.shore_net, text.shore_vol = icons[net_glyph()] or "", icons[volume_glyph()] or ""
    text.shore_bat = has_battery and (icons[battery_glyph()] or "") or ""
    text.shore_arrow = icons[fact.shore_open and "chevron-down" or "chevron-up"] or ""
    show_layout()
end
-- how long the plate is: the arrow, the programs, the signs
local function lay_out()
    local list = {}
    shown_bg = {}
    for _, t in ipairs(tray) do
        if #list >= 10 then break end
        -- ToolHive's icon is in LensAI (under ToolHive Studio, the same menu): not here twice (the user, 21. 11.)
        if string.find(string.lower(t.id or ""), "toolhive", 1, true) then continue end
        local i = #list + 1
        shown_bg[i] = t
        list[i] = { icon = t.icon or "", has_icon = (t.icon or "") ~= "", glyph = icons["apps"], title = (t.title or "") ~= "" and t.title or (t.id or "") }
    end
    model.bg = list
    local signs = has_battery and 3 or 2
    fact.shore_signs = signs
    local kb = #layout_names() >= 2 and 1 or 0
    fact.shore_kb = kb
    -- hidden as a drop is (Settings › Drops, the look Minimal: "trayshore" in `hidden`, ROADMAP 6.39): no plate at all
    local gone = false
    for _, id in ipairs(E.settings().hidden or {}) do if id == "trayshore" then gone = true end end
    fact.shore_w = gone and 0 or (65 + 30 * #list + 34 * signs + 38 * kb)
    E.shore(fact.shore_w, HEIGHT)
    show_signs()
end
-- A page of the panel: a card that stands on the shore and reaches the top of the screen.
local function panel(rows, opts)
    opts = opts or {}
    local w, h = tonumber(fact.sw) or 1920, tonumber(fact.sh) or 1080
    local at = tonumber(fact.tray_at) or -1                    -- carried off the corner (6.36): the panel stands on it there
    fact["tap.x"], fact["tap.y"] = (at >= 0 and at + (tonumber(fact.shore_w) or 0) or w) - 6, h - HEIGHT - 4
    opts.id, opts.owner, opts.dock = "shore", nil, tonumber(fact.shore_w) or 0
    opts.width = opts.width or 320
    card.open(rows, opts)
    if not fact.shore_open then fact.shore_open = true show_signs() E.shore_moved() end
end
local function read_clips(then_do) clipboard.read(8, 60, function(list) clips = list then_do() end) end
local function refresh()
    if card.id() ~= "shore" then return end
    -- only what shows live state is drawn again: a program's menu, the Wi-Fi password, "forget" and the keyboard's
    -- menu stay as they are (each change of the network or the sound put the main panel back over them; the audit, 24. 11.)
    if showing == "networks" then open_networks(true) elseif showing == "devices" then open_devices(true)
    elseif showing == "sound" then open_sound(true) elseif showing == "main" then open_main(true) end
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
-- What NetworkManager knows beyond pleamar's `network` (nmcli, read when the page opens): the VPNs and whether the radios
-- are off (airplane mode), and on asking the connection's details, as Windows 11's network properties
local vpns, airplane = {}, false
local C = { env = { LC_ALL = "C" } }          -- nmcli says yes and enabled in the user's language otherwise
local function read_extra(then_do)
    run("nmcli", { "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show" }, function(out)
        local list = {}
        for line in string.gmatch(out or "", "[^\n]+") do
            local name, kind, active = string.match(line, "^(.*):([%w-]+):(%a+)$")
            if name and (kind == "vpn" or kind == "wireguard") then list[#list + 1] = { name = name:gsub("\\:", ":"), active = active == "yes" } end
        end
        vpns = list
        run("nmcli", { "-t", "radio", "all" }, function(r)
            local wifi = select(2, string.match(r or "", "^(%a+):(%a+)")) or "enabled"
            airplane = wifi == "disabled" and not blue.powered
            if then_do then then_do() end
        end, C)
    end, C)
end
local function open_details()
    showing = "details"
    run("sh", { "-c", 'export LC_ALL=C; d=$(nmcli -t -f DEVICE,STATE device | awk -F: \'$2=="connected"{print $1; exit}\'); [ -n "$d" ] || exit 0; '
               .. 'nmcli -t -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,CAPABILITIES.SPEED device show "$d"; '
               .. 'nmcli -t -f ACTIVE,SSID,RATE,SIGNAL,SECURITY,FREQ device wifi list ifname "$d" --rescan no 2>/dev/null | grep "^yes:"' }, function(out)
        if showing ~= "details" then return end
        local v, dns = {}, {}
        for line in string.gmatch(out or "", "[^\n]+") do
            local k, val = string.match(line, "^([%w%.%[%]_-]+):(.*)$")
            if k and k:find("^IP4%.DNS") then dns[#dns + 1] = val
            elseif k and k ~= "yes" then v[k:gsub("%[%d+%]$", "")] = v[k:gsub("%[%d+%]$", "")] or val end
            if line:find("^yes:") then
                local f = {}
                for part in string.gmatch((line:gsub("\\:", "\1")) .. ":", "([^:]*):") do f[#f + 1] = part:gsub("\1", ":") end
                v.ssid, v.rate, v.signal, v.security, v.freq = f[2], f[3], f[4], f[5], f[6]
            end
        end
        local rows = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_networks() end },
                       { head = true, label = tr("PROPERTIES"), line = true } }
        local function row(label, value, glyph)      -- what is not known is left out; each can be copied
            if (value or "") == "" or value == "--" then return end
            rows[#rows + 1] = { label = value, hint = label, glyph = glyph, copy = value, quiet = true }
        end
        do
            row(tr("Network"), v.ssid, "wifi")
            row(tr("Adapter"), (v["GENERAL.DEVICE"] or "") .. ((v["GENERAL.TYPE"] or "") ~= "" and ("  ·  " .. v["GENERAL.TYPE"]) or ""), "network")
            row(tr("IPv4 address"), v["IP4.ADDRESS"], "world")
            row(tr("Gateway"), v["IP4.GATEWAY"], "router")
            row(tr("DNS servers"), table.concat(dns, ", "), "server")
            row(tr("IPv6 address"), v["IP6.ADDRESS"], "world")
            row(tr("Speed"), v.rate or v["CAPABILITIES.SPEED"], "gauge")
            row(tr("Signal"), v.signal and (v.signal .. " %") or nil, "antenna-bars-5")
            local mhz = tonumber(string.match(v.freq or "", "%d+"))
            row(tr("Band"), mhz and ((mhz >= 5925 and "6 GHz" or mhz >= 4900 and "5 GHz" or "2,4 GHz") .. "  ·  " .. v.freq) or v.freq, "wave-sine")
            row(tr("Security"), v.security, "lock")
            row(tr("Physical address (MAC)"), v["GENERAL.HWADDR"], "fingerprint")
        end
        if #rows == 2 then rows[#rows + 1] = { label = tr("Not connected"), glyph = "wifi-off", quiet = true } end
        rows[#rows + 1] = { label = tr("Network settings"), glyph = "settings", line = true, run = function() open.settings("network") end }
        panel(rows, { width = 380 })
    end)
end
local function ask_hidden()
    showing = "password"
    panel({ back(), { label = tr("A hidden network"), glyph = "wifi", quiet = true, line = true } },
          { width = 320, field = { hint = tr("The network's name (SSID)"), submit = function(ssid)
              ssid = (ssid or ""):gsub("^%s+", ""):gsub("%s+$", "")
              if ssid == "" then return false end
              panel({ back(), { label = ssid, glyph = "lock", quiet = true, line = true } },
                    { width = 320, field = { hint = tr("Password (empty for an open network)"), secret = true, submit = function(pw)
                        local args = { "device", "wifi", "connect", ssid }
                        if (pw or "") ~= "" then args[#args + 1] = "password" args[#args + 1] = pw end
                        args[#args + 1] = "hidden" args[#args + 1] = "yes"
                        run("nmcli", args, function() open_networks() end, C)
                        return false
                    end } })
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
    if net.kind == "wired" and net.online then rows[#rows + 1] = { label = tr("Wired network"), glyph = "network", hint = tr("connected"), more = true, keep = true, run = open_details } end
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
                local menu = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() open_networks() end } }
                if n.active then menu[#menu + 1] = { label = tr("Properties"), glyph = "info-circle", line = true, keep = true, run = open_details } end
                if n.known then menu[#menu + 1] = { label = tr("Forget this network"), glyph = "trash", danger = true, line = not n.active, keep = true,
                                                     run = function() call("network.forget", n.ssid) open_networks() end } end
                if #menu == 1 then return end
                panel(menu, { width = 320 })
                showing = "forget"
            end,
        }
    end
    if net.wifi and #(net.networks or {}) == 0 then rows[#rows + 1] = { label = tr("Looking for networks…"), glyph = "wifi-1", quiet = true, line = true } end
    if has_wifi and net.wifi then rows[#rows + 1] = { label = tr("A hidden network…"), glyph = "wifi-off", line = true, keep = true, run = ask_hidden } end
    -- the VPNs NetworkManager has: a press turns one on or off
    for i, v in ipairs(vpns) do
        rows[#rows + 1] = { label = v.name, glyph = "shield-lock", on = v.active, hint = tr(v.active and N("connected") or N("off")), line = i == 1, keep = true,
                            run = function() run("nmcli", { "connection", v.active and "down" or "up", "id", v.name }, function() read_extra(function() open_networks(true) end) end, C) end }
    end
    -- airplane mode: every radio off (Wi-Fi, mobile, Bluetooth), as on Windows; again: Wi-Fi and Bluetooth back
    rows[#rows + 1] = { label = tr("Airplane mode"), glyph = "plane", on = airplane, hint = tr(airplane and N("on") or N("off")), line = true, keep = true,
                        run = function()
                            local off = not airplane
                            run("nmcli", { "radio", "all", off and "off" or "on" }, function() read_extra(function() open_networks(true) end) end, C)
                            call("bluetooth.power", not off)
                        end }
    if net.online then rows[#rows + 1] = { label = tr("Properties"), glyph = "info-circle", keep = true, run = open_details } end
    rows[#rows + 1] = { label = tr("Network settings"), glyph = "settings", run = function() open.settings("network") end }
    panel(rows, { width = 320, keep = keep })
    if not keep then
        if net.wifi then call("network.scan") end
        read_extra(function() if showing == "networks" then open_networks(true) end end)
    end
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
-- As Windows 11's sound flyout: the volume, the speaker it goes to, each app that plays with a volume of its own (the
-- volume mixer: pleamar's `audio.apps`, `audio.app_volume`, `audio.app_mute`), the microphone, and Settings › Sound.
local function output_glyph(name)
    local n = string.lower(name or "")
    if n:find("headphone", 1, true) or n:find("headset", 1, true) then return "headphones" end
    if n:find("hdmi", 1, true) or n:find("displayport", 1, true) then return "device-tv" end
    if n:find("usb", 1, true) or n:find("bluetooth", 1, true) or n:find("bluez", 1, true) then return "device-speaker" end
    return "device-speaker"
end
open_sound = function(keep)
    showing = "sound"
    local rows = { back(), { head = true, label = tr("OUTPUT"), line = true } }
    if audio.volume ~= nil then
        rows[#rows + 1] = { slide = true, glyph = volume_glyph(), label = output_name() ~= "" and output_name() or tr("Volume"), value = audio.volume,
                            off = audio.muted == true, hint = percent(audio.volume), run = function() call("audio.mute") end,
                            set = function(v) call("audio.volume", v) end, wheel = function(dir) call("audio.step", dir * 0.05) end }
    end
    local outs = audio.outputs or {}
    if #outs > 1 then
        for i, o in ipairs(outs) do
            if i > 6 then break end
            rows[#rows + 1] = { label = o.name or "", glyph = output_glyph(o.name), on = o.default == true, line = i == 1, keep = true,
                                run = function() call("audio.default", o.id) end }
        end
    end
    -- each app that plays now: its own volume, a press on its sign mutes it
    local apps = audio.apps or {}
    if #apps > 0 then
        rows[#rows + 1] = { head = true, label = tr("VOLUME MIXER"), line = true }
        for i, a in ipairs(apps) do
            if i > 8 then break end
            local name = (a.name or "") ~= "" and a.name or ((a.binary or "") ~= "" and a.binary or tr("An app"))
            local id = tonumber(a.id)
            -- a slider says no name (parts/rows.plm): the app's name above it, what it plays beside
            local what = (a.title or "") ~= "" and a.title ~= name and a.title or ""
            rows[#rows + 1] = { label = name, hint = #what > 28 and (string.sub(what, 1, 26) .. "…") or what, glyph = "app-window", quiet = true, line = i > 1 }
            rows[#rows + 1] = { slide = true, glyph = a.muted and "volume-off" or (a.playing and "volume" or "volume-2"), label = name,
                                value = tonumber(a.volume) or 0, off = a.muted == true, hint = percent(a.volume),
                                run = function() if id then call("audio.app_mute", id) end end,
                                set = function(v) if id then call("audio.app_volume", id, v) end end,
                                wheel = function(dir) if id then call("audio.app_volume", id, math.clamp((tonumber(a.volume) or 0) + dir * 0.05, 0, 1)) end end }
        end
    end
    rows[#rows + 1] = { head = true, label = tr("INPUT"), line = true }
    rows[#rows + 1] = { slide = true, glyph = audio.input_muted and "microphone-off" or "microphone", label = tr("Microphone"), value = audio.input or 0,
                        off = audio.input_muted == true, hint = percent(audio.input), run = function() call("audio.input_mute") end,
                        set = function(v) call("audio.input", v) end, wheel = function(dir) call("audio.input", math.clamp((audio.input or 0) + dir * 0.05, 0, 1)) end }
    local ins = audio.inputs or {}
    if #ins > 1 then
        for i, o in ipairs(ins) do
            if i > 4 then break end
            rows[#rows + 1] = { label = o.name or "", glyph = "microphone", on = o.default == true, keep = true,
                                run = function() call("audio.default", o.id) end }
        end
    end
    rows[#rows + 1] = { label = tr("Sound settings"), glyph = "settings", line = true, run = function() open.settings("sound") end }
    panel(rows, { width = 360, keep = keep })
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
-- the keyboard sign's right button (as Windows 11's language sign): the layouts by their names, the one typed in
-- ticked, a press turns to it; the character map and Settings › Keyboard
local layout_full = {}                      -- "sk" → "Slovak", as latte-settings names them (in the user's language)
local function open_keyboard()
    showing = "keyboard"
    local names, now = layout_names(), (tonumber(fact.kb_layout) or 0) + 1
    local rows = { { head = true, label = tr("Keyboard layout"), line = true } }
    for i, code in ipairs(names) do
        local steps = (i - now) % math.max(#names, 1)
        rows[#rows + 1] = { label = layout_full[code] or string.upper(code), hint = string.upper(code), on = i == now, glyph = i == now and "check" or "keyboard",
                            run = function()
                                -- pleamar-wm turns to the next one at each touch (patches/pleamar-wm-zz-layout.patch)
                                if steps > 0 then run("sh", { "-c", 'for i in $(seq ' .. steps .. '); do touch "${XDG_RUNTIME_DIR:-/tmp}/pleamar-wm-layout-next"; sleep 0.2; done' }, function() end) end
                            end }
    end
    rows[#rows + 1] = { label = tr("Character map"), glyph = "cursor-text", line = true, run = function() run("gtk-launch", { "gucharmap" }, function() end) end }
    rows[#rows + 1] = { label = tr("Keyboard settings"), glyph = "settings", run = function() open.settings("keyboard") end }
    panel(rows, { width = 300 })
    if next(layout_full) == nil then
        run("latte-settings", { "keyboard" }, function(out)
            local ok, d = pcall(json.decode, out or "")
            if not ok or type(d) ~= "table" or type(d.layouts) ~= "table" then return end
            for _, l in ipairs(d.layouts) do if l.id and l.name then layout_full[l.id] = l.name end end
            if next(layout_full) ~= nil and showing == "keyboard" and card.id() == "shore" then open_keyboard() end
        end)
    end
end

local function open_menu(t)
    local ok, items = pcall(sys.ask, "tray.menu", t.key)
    -- Electron's tray says no title, only "App_status_icon_1": its name without the rest
    local name = (((t.title or "") ~= "" and t.title or t.id or ""):gsub("_status_icon_%d+$", ""))
    local rows = { back(), { head = true, label = name, line = true } }
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
    -- under it: what is going on
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
        right[#right + 1] = { label = c.text, glyph = "clipboard", run = function() clipboard.copy(c.id) end }
    end
    if #clips > 0 then
        right[#right + 1] = { label = tr("Forget what was copied"), glyph = "trash", danger = true, keep = true,
                              run = function() clipboard.wipe(function() clips = {} open_main(true) end) end }
    end
    -- one column, standing up from the plate (the user, 13 Nov: it opened wide and low; ROADMAP 6H.09)
    for _, r in ipairs(right) do rows[#rows + 1] = r end
    panel(rows, { width = 360, keep = keep, tiles = true })
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
    -- the keyboard's sign: the next layout (pleamar-wm takes the file away and changes it, wm/session.plm tells the scene back)
    on("shore_kb_press", function() run("sh", { "-c", 'touch "${XDG_RUNTIME_DIR:-/tmp}/pleamar-wm-layout-next"' }, function() end) end)
    on("fact:kb_layout", show_signs)
    on("shore_kb_right", function() open_keyboard() end)
    on("quick_toggle", M.toggle)
    on("shore_sign", function(s)
        if s == 0 then read_clips(function() open_networks() end) else M.toggle() end
    end)
    on("shore_sign_right", function(s) if s == 1 then call("audio.mute") end end)
    on("shore_wheel", function(v) if (v or 0) // 2 == 1 then call("audio.step", ((v or 0) % 2 == 1 and 1 or -1) * 0.05) end end)
    -- a press: the program's own action; one that has none (Steam, Solaar… say only a menu: "No such method Activate")
    -- opens its menu instead, as KDE and Windows do
    on("shore_bg", function(j)
        local t = shown_bg[(j or 0) + 1]
        if not t then return end
        if not pcall(sys.call, "tray.activate", t.key) then open_menu(t) end
    end)
    on("shore_bg_right", function(j) local t = shown_bg[(j or 0) + 1] if t then open_menu(t) end end)
    -- the same menu for one kept out of the plate (ToolHive: its place is in LensAI), asked by its id and where it was pressed
    -- ("toolhive,X,Y", the pointer then): the card grows from there, not from the shore; emptied so the next press asks anew
    on("text:shore_tray", function()
        local want, x, y = string.match(string.lower(text.shore_tray or ""), "^([%w_-]+),?(%-?[%d.]*),?(%-?[%d.]*)")
        if not want or want == "" then return end
        text.shore_tray = ""
        for _, t in ipairs(tray) do
            if string.find(string.lower(t.id or ""), want, 1, true) then
                if tonumber(x) and tonumber(y) then
                    local ok, items = pcall(sys.ask, "tray.menu", t.key)
                    local name = (((t.title or "") ~= "" and t.title or t.id or ""):gsub("_status_icon_%d+$", ""))
                    local rows = { { head = true, label = name, line = true } }
                    for _, r in ipairs(ok and menu_rows(t.key, items) or {}) do rows[#rows + 1] = r end
                    fact["tap.x"], fact["tap.y"] = tonumber(x), tonumber(y)
                    card.open(rows, { id = "traymenu", width = 320 })
                else
                    open_menu(t)
                end
                return
            end
        end
    end)
    on("shore_hover", function(what) text.tip = tip_for(what or 0) end)
    -- the arrow turns back when the panel goes, whoever closed it
    card.watch(function(id) if fact.shore_open and id ~= "shore" then fact.shore_open = false show_signs() E.shore_moved() end end)
    lay_out()
    pcall(sys.watch, "files:settings.json", function() after(100, lay_out) end)   -- shown again, or hidden, at once (after lib/engine.luau read it)
end

return M
