-- engine Goo — wm: ovládanie okien a plochy na jednom mieste. Dva ovládače: Hyprland (hyprctl, funkcie latte.* z
-- session/hypr/latte/*.lua; správanie je presne to, čo bolo predtým priamo v moduloch) a labwc (SafeGoo: príkazy služby
-- `window` pleamaru cez wlr-foreign-toplevel podľa id okna — ukázať, minimalizovať, obnoviť, zavrieť). Čo labwc nevie
-- (rozloženia, režimy okien, navrchu, plochy), je `wm.caps.* = false` a moduly to nenúkajú. Ostatné moduly nevolajú
-- `hyprctl` priamo. Okno: tabuľka zo služby `window` ({ id, class, title, active, minimized }) a `nth` (poradie
-- okien s rovnakou triedou a titulkom — iba Hyprland ho hľadá podľa nich).
local M = {}

local function envget(n) local ok, v = pcall(sys.ask, "env", n) return ok and type(v) == "string" and v or "" end
M.safe = envget("LATTE_MODE") == "safe" or envget("XDG_CURRENT_DESKTOP"):find("labwc", 1, true) ~= nil

local hl = not M.safe
M.caps = { layout = hl, modes = hl, pin = hl, desks = hl, maximize = hl, clients = hl }

local function hyprctl(args, cb) run("hyprctl", args, cb) end
local function eval(lua, cb) hyprctl({ "eval", lua }, cb) end
local function call(cmd, id) if id then pcall(sys.call, cmd, id) end end

-- okno ukázať a dať mu klávesnicu (fn = "focus_by"), alebo neaktívne ukázať a aktívne minimalizovať (fn = "toggle_by")
function M.win(fn, w, nth)
    if not w then return end
    if M.safe then
        if fn == "toggle_by" and w.active and not w.minimized then call("window.minimize", w.id)
        else call("window.restore", w.id) end
        return
    end
    eval(string.format("latte.win.%s(%q, %q, %d)", fn, w.class or "", w.title or "", nth or 1))
end

-- okno aplikácie podľa triedy a titulku (kvapka QueenGoo): ukázať ho
function M.focus_app(class, title, w)
    if M.safe then if w then call("window.restore", w.id) end return end
    eval("latte.win.focus_by('" .. class .. "', '" .. title .. "')")
end

-- akcia z ponuky okna (restore | minimize | close); Hyprland ju robí cez latte.okno.* v goobar.luau
function M.act(what, w)
    if not w then return end
    call("window." .. what, w.id)
end

-- aktívne okno: cb(tabuľka | nil); Hyprland dá celý záznam hyprctl (address, fullscreen, workspace…), labwc iba id
function M.active(cb)
    if M.safe then cb(nil) return end
    hyprctl({ "-j", "activewindow" }, function(out)
        local ok, w = pcall(json.decode, out or "")
        cb(ok and type(w) == "table" and w or nil)
    end)
end

-- všetky okná Hyprlandu s monitorom a plochou: cb(zoznam | nil); labwc nepozná (cb(nil) → moduly berú zoznam služby)
function M.clients(cb)
    if M.safe then cb(nil) return end
    hyprctl({ "-j", "clients" }, function(out)
        local ok, list = pcall(json.decode, out or "")
        cb(ok and type(list) == "table" and list or nil)
    end)
end

-- hlava Goobaru: ďalší režim okien (iba Hyprland), ukázať plochu, koliesko
function M.cycle_mode(cb) if not hl then return end eval('require("latte.windows").cycle()', cb) end
function M.show_desktop() if not hl then return end eval("latte.keys.show_desktop()") end
function M.scroll(dir, px) if not hl then return end eval(string.format('hl.dispatch(hl.dsp.layout("move %s%d"))', dir > 0 and "-" or "+", px)) end
function M.cycle(dir) if not hl then return end eval("latte.win.cycle(" .. dir .. ")") end

-- akcia latte.okno.<fn>('<adresa>'[, arg]) a rozloženie okna (iba Hyprland; adresa z `active`)
function M.okno(fn, address, arg) if not hl then return end eval(string.format("latte.okno.%s('%s'%s)", fn, address, arg and ("," .. arg) or "")) end
function M.rozlozenie(address, zone) if not hl then return end eval(string.format("latte.okno.rozlozenie('%s','%s')", address, zone)) end

-- Noctalia (`noctalia msg …`): v safe režime nebeží, volanie sa preskočí
function M.noctalia(args, cb, opts) if M.safe then return end run("noctalia", args, cb, opts) end

-- ponuka relácie GooPower (lock | logout | suspend | reboot | shutdown): Hyprland cez Noctaliu, labwc priamo
local SAFE_SESSION = {
    lock = { "latte-zamok", {} }, logout = { "labwc", { "--exit" } }, suspend = { "systemctl", { "suspend" } },
    reboot = { "systemctl", { "reboot" } }, shutdown = { "systemctl", { "poweroff" } },
}
function M.session(a)
    if not M.safe then run("noctalia", { "msg", "session", a }) return end
    local c = SAFE_SESSION[a]
    if c then run(c[1], c[2]) end
end

return M
