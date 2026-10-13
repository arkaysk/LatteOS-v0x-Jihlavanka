-- QueenGoo: the apps and the devices of this computer. She wears a crown, and beads say what waits: blue for
-- updates, red for a device that needs attention, green when the network is down.
-- A press opens the App Manager, at the updates when some wait; the right button the Device Manager, at the
-- network when that is down.
local open = require("lib/open")

local updates, offline, faults = 0, false, 0
local function show(d)
    local beads = {}
    if faults > 0 then beads[#beads + 1] = "hardware" end
    if offline then beads[#beads + 1] = "network" end
    if updates > 0 then beads[#beads + 1] = "software" end
    d:set_beads(#beads, #beads > 0 and beads or nil)
end
local function look(d)
    run("latte-apps", { "updates" }, function(out)
        local ok, u = pcall(json.decode, out or "")
        if not ok or type(u) ~= "table" then return end
        updates = #(type(u.apps) == "table" and u.apps or {}) + ((tonumber(u.system) or 0) > 0 and 1 or 0)
        show(d)
    end)
    run("latte-devices", { "faults" }, function(out)
        faults = tonumber((out or ""):match("%d+")) or 0
        show(d)
    end)
end

return {
    id = "queengoo", name = "QueenGoo", glyph = "package", crown = "crown", nature = "calm", size = 25, seat = 17, swell = 0.1,
    home = { edge = 0, at = 0.64 },
    about = function()
        return (faults > 0 and (tr("a device needs attention") .. " · ") or "") .. (updates > 0 and (tr("updates wait") .. " · ") or "")
            .. tr("left: App Manager · right: Device Manager")
    end,
    start = function(d)
        -- a while after the start, so as not to compete with it, and then every few hours
        after(40000, function() look(d) end)
        every(3 * 3600 * 1000, function() look(d) end)
        pcall(sys.watch, "network", function(n)
            local down = type(n) == "table" and n.online == false
            if down ~= offline then offline = down show(d) end
        end)
    end,
    click = function(d)
        open.apps(updates > 0 and "updates" or nil)
        after(60000, function() look(d) end)          -- what was updated there no longer waits
    end,
    right = function() open.devices(offline and "network" or nil) end,
}
