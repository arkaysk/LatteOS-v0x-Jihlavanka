-- What the shell asks of the compositor, in one place: no other module names Hyprland.
-- Windows are told apart by the address Hyprland gives them; what is done to one is a function of
-- system/hypr/latte/windows.lua, called through `hyprctl eval`.
local M = {}

local function hyprctl(args, cb) run("hyprctl", args, cb) end
local function eval(lua) hyprctl({ "eval", lua }) end
local function decode(out)
    local ok, t = pcall(json.decode, out or "")
    return ok and type(t) == "table" and t or nil
end

-- Every window there is: answer(list), each { address, class, title, pid, desk, here (it is on the scene's own
-- monitor), visible (on a desktop that is shown), away (put away), front (it has the keyboard), maximized,
-- fullscreen, floating, pinned, x, y, w, h }; nil without a compositor. x and y are counted from the corner of
-- the scene's monitor, as everything in the scene is.
local SCREEN = (function() local ok, v = pcall(sys.ask, "env", "LATTE_GOO_SCREEN") return ok and type(v) == "string" and v or "" end)()
local own = { id = nil, x = 0, y = 0 }       -- the scene's monitor, as the compositor knows it
function M.monitor() return own.id end
function M.origin() return own.x, own.y end  -- its corner among the monitors
function M.windows(answer)
    -- one call: the answers come one after the other, with empty lines between them
    hyprctl({ "--batch", "j/clients ; j/activewindow ; j/monitors" }, function(out)
        local first, second, third = (out or ""):match("^(.-)\n\n\n(.-)\n\n\n(.*)$")
        local list = decode(first)
        if not list then return answer(nil) end
        local front = (decode(second) or {}).address
        -- The scene is on the monitor it was started for; started for none, on the one that has the pointer.
        local mine
        for _, m in ipairs(decode(third) or {}) do
            if m.name == SCREEN or (SCREEN == "" and m.focused and not mine) then mine = m end
        end
        if mine then own = { id = tonumber(mine.id), x = tonumber(mine.x) or 0, y = tonumber(mine.y) or 0 } end
        local wins = {}
        for _, c in ipairs(list) do
            if c.mapped ~= false and (c.class or "") .. (c.title or "") ~= "" then
                local ws = type(c.workspace) == "table" and c.workspace or {}
                local at, size = type(c.at) == "table" and c.at or {}, type(c.size) == "table" and c.size or {}
                local away = tostring(ws.name or ""):find("^special:minimized") ~= nil
                wins[#wins + 1] = {
                    address = c.address, class = c.class or "", title = c.title or "", pid = c.pid,
                    here = own.id == nil or tonumber(c.monitor) == own.id,
                    desk = tonumber(ws.id) or 0, visible = c.visible == true and not away, away = away, front = c.address == front and not away,
                    maximized = c.fullscreen == 1, fullscreen = (tonumber(c.fullscreen) or 0) >= 2, floating = c.floating == true,
                    pinned = c.pinned == true, x = (tonumber(at[1]) or 0) - own.x, y = (tonumber(at[2]) or 0) - own.y,
                    w = tonumber(size[1]) or 0, h = tonumber(size[2]) or 0,
                }
            end
        end
        answer(wins)
    end)
end

-- what: activate · toggle · minimize · restore · maximize · close · pin · snap (arg: the zone) · to_desk (arg: its number)
function M.win(what, address, arg)
    if not address then return end
    eval(string.format("latte.win.%s(%q%s)", what, address, arg ~= nil and (", " .. (type(arg) == "string" and string.format("%q", arg) or tostring(arg))) or ""))
end
-- the windows that play a sound now (their addresses): the compositor shows it on each one's border
function M.sounding(addresses)
    local quoted = {}
    for i, a in ipairs(addresses) do quoted[i] = string.format("%q", a) end
    eval("latte.win.sounding({" .. table.concat(quoted, ", ") .. "})")
end
function M.cycle(dir) eval("latte.win.cycle(" .. dir .. ")") end          -- the next window, or the one before
function M.scroll(dir) eval("latte.win.scroll(" .. dir .. ")") end        -- the tape, by a quarter of the screen
function M.next_mode() eval("latte.mode.next()") end                      -- the answer comes as the event `window_mode`
function M.tell_mode() eval("latte.mode.tell()") end
function M.set_mode(n) eval(string.format("latte.mode.set(%q)", ({ [0] = "tape", "tiles", "floating" })[n] or "tape")) end
function M.glass(on) eval("latte.glass(" .. tostring(on == true) .. ")") end   -- the windows of glass too, where the card can
function M.wallpaper(path) eval(string.format("latte.wallpaper(%q)", path)) end
function M.show_desktop() eval("latte.desk.show()") end
-- the band along an edge that windows leave to the drops: 0 bottom, 1 left, 2 top, 3 right
function M.band(edge) eval(string.format("latte.band(%q, %q)", ({ [0] = "bottom", "left", "top", "right" })[edge] or "bottom", SCREEN)) end
function M.logout() eval("hl.dispatch(hl.dsp.exit())") end
-- started by the compositor, so logind sees the login session; the engine itself is outside it and polkit would ask for a password nobody answers
function M.machine(what) eval(string.format("hl.exec_cmd(%q)", "systemctl " .. what)) end

return M
