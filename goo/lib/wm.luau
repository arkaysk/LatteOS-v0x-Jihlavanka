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

-- Every window there is: answer(list), each { address, class, title, pid, monitor, desk, visible (on a desktop
-- that is shown), away (put away), front (it has the keyboard), maximized, fullscreen, floating, pinned,
-- x, y, w, h }; nil without a compositor.
function M.windows(answer)
    -- one call: the two answers come one after the other, with empty lines between them
    hyprctl({ "--batch", "j/clients ; j/activewindow" }, function(out)
        local first, second = (out or ""):match("^(.-)\n\n\n(.*)$")
        local list = decode(first)
        if not list then return answer(nil) end
        local front = (decode(second) or {}).address
        local wins = {}
        for _, c in ipairs(list) do
            if c.mapped ~= false and (c.class or "") .. (c.title or "") ~= "" then
                local ws = type(c.workspace) == "table" and c.workspace or {}
                local at, size = type(c.at) == "table" and c.at or {}, type(c.size) == "table" and c.size or {}
                local away = tostring(ws.name or ""):find("^special:minimized") ~= nil
                wins[#wins + 1] = {
                    address = c.address, class = c.class or "", title = c.title or "", pid = c.pid, monitor = tonumber(c.monitor),
                    desk = tonumber(ws.id) or 0, visible = c.visible == true and not away, away = away, front = c.address == front and not away,
                    maximized = c.fullscreen == 1, fullscreen = (tonumber(c.fullscreen) or 0) >= 2, floating = c.floating == true,
                    pinned = c.pinned == true, x = tonumber(at[1]) or 0, y = tonumber(at[2]) or 0, w = tonumber(size[1]) or 0, h = tonumber(size[2]) or 0,
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
function M.cycle(dir) eval("latte.win.cycle(" .. dir .. ")") end          -- the next window, or the one before
function M.scroll(dir) eval("latte.win.scroll(" .. dir .. ")") end        -- the tape, by a quarter of the screen
function M.next_mode() eval("latte.mode.next()") end                      -- the answer comes as the event `window_mode`
function M.tell_mode() eval("latte.mode.tell()") end
function M.show_desktop() eval("latte.desk.show()") end
-- the band along an edge that windows leave to the drops: 0 bottom, 1 left, 2 top, 3 right
function M.band(edge) eval(string.format("latte.band(%q)", ({ [0] = "bottom", "left", "top", "right" })[edge] or "bottom")) end
function M.logout() eval("hl.dispatch(hl.dsp.exit())") end

return M
