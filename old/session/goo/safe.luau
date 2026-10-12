-- SAFE: logika núdzového rozhrania. Hlási stav scéne (údaje, okná, batéria, sieť, čas), spúšťa programy z tlačidiel a obsluhuje
-- riadok na písanie z LensGoo (režimy: aplikácie · súbory a priečinky · AI · Linux príkaz). Bez engine Goo (rozhodnutie 8. 10.);
-- pomocníci sú tí istí ako v LensGoo (latte-hladaj, latte-ai, latte-terminal), zdieľané lib/fold.luau a lib/nebezpecne.luau.
local fold = require("lib/fold")
local dangerous = require("lib/nebezpecne")

local function go(cmd, args) run(cmd, args or {}, nil, { output = false }) end
local function lines(out) local t = {} for l in (out or ""):gmatch("[^\n]+") do t[#t + 1] = l end return t end

on("safe_menu", function() go("foot", { "-T", "LatteOS SAFE", "-e", "latte-safe" }) end)
on("appmgr", function() go("latte-app", { "aplikacie" }) end)
on("devmgr", function() go("latte-app", { "zariadenia" }) end)
on("term", function() go("latte-terminal") end)

-- ponuka vypnutia: poradie ako v scéne
local POWER = {
    [0] = function() go("latte-zamok") end,
    function() go("labwc", { "--exit" }) end,
    function() go("systemctl", { "suspend" }) end,
    function() go("systemctl", { "reboot" }) end,
    function() go("systemctl", { "poweroff" }) end,
}
on("pw_act", function(i) local f = POWER[tonumber(i) or -1] if f then f() end end)

-- ── údaje ako v GooPower (latte-sysmon goo): CPU · RAM · GPU · VRAM ──────────────────────────────────────────────
local function gb(b) return string.format("%.1f G", (b or 0) / 1073741824):gsub("%.", ",") end
local function stream()
    spawn("latte-sysmon", { "goo", "1" }, function(line)
        local ok, s = pcall(json.decode, line or "")
        if not ok or type(s) ~= "table" then return end
        local t = "CPU " .. (s.cpu or 0) .. " %   RAM " .. gb(s.ram)
        if s.gpu ~= nil then t = t .. "   GPU " .. s.gpu .. " %" end
        if (s.vramT or 0) > 0 then t = t .. "   VRAM " .. gb(s.vram) end
        text.stats = t
    end, function() after(3000, stream) end)              -- spadol: znova
end
stream()

-- ── čas a dátum ako na prihlasovacej obrazovke (lib/prihlasenie.luau) ────────────────────────────────────────────
local function clock()
    run("date", { "+%H:%M|%A %-d. %B" }, function(out)
        local c, d = (out or ""):match("^(%d+:%d+)|(.-)%s*$")
        if c then text.cas, text.datum = c, d or "" end
    end)
end
clock()
every(10000, clock)

-- ── okná: zoznam a klik (neaktívne ukáže, aktívne minimalizuje) ──────────────────────────────────────────────────
local list = {}
sys.watch("window", function(v)
    list = (v and v.list) or {}
    local rows, n = {}, 0
    for _, w in ipairs(list) do
        if n >= 3 then break end
        n = n + 1
        local t = w.title
        if t == nil or t == "" then t = w.class or "" end
        rows[n] = { title = t, active = w.active and 1 or 0 }
    end
    model.wins = rows
    fact.nwins = n
end)
on("win_go", function(i)
    local w = list[(tonumber(i) or -1) + 1]
    if not w then return end
    if w.active and not w.minimized then pcall(sys.call, "window.minimize", w.id) else pcall(sys.call, "window.restore", w.id) end
end)

sys.watch("battery", function(b) fact.bat = (b and b.present) and math.floor((b.percent or 0) + 0.5) or -1 end)
sys.watch("network", function(n) text.net = (n and n.online) and (n.name or n.kind or "online") or "offline" end)

-- ── riadok na písanie z LensGoo ──────────────────────────────────────────────────────────────────────────────────
local MODES = {
    { id = "apps", icon = "system-search-symbolic", hint = "Search apps…" },
    { id = "files", icon = "folder-symbolic", hint = "Search files and folders…" },
    { id = "ai", icon = "starred-symbolic", hint = "Ask AI…" },
    { id = "code", icon = "utilities-terminal-symbolic", hint = "Run a Linux command…" },
}
local mode, gen, confirm = 1, 0, nil
local apps, rows = {}, {}                  -- aplikácie zo služby `apps`; aktuálne výsledky (riadky s akciou)
pcall(sys.watch, "apps", function(l) apps = l or {} end)

local function set_rows(r)
    rows = r or {}
    local m = {}
    for i, x in ipairs(rows) do if i <= 8 then m[i] = { title = x.title, sub = x.sub or "", icon = x.icon or "" } end end
    model.res = m
    fact.nres = math.min(#rows, 8)
end
local function clear() text.q = "" confirm = nil set_rows({}) end
local function show_mode()
    local m = MODES[mode]
    text.mode_icon, text.hint = m.icon, tr(m.hint)
    fact.qempty = (text.q or "") == "" and 1 or 0
end
show_mode()

-- aplikácie: názov (začiatok > začiatok slova > kdekoľvek), potom id
local function find_apps(q)
    local fq, out = fold(q), {}
    for _, a in ipairs(apps) do
        local name = fold(a.name)
        local at = name:find(fq, 1, true)
        local s = at == 1 and 3 or (at and name:sub(at - 1, at - 1):match("[%s%-_]") and 2) or (at and 1) or (fold(a.id):find(fq, 1, true) and 0.5) or 0
        if s > 0 then out[#out + 1] = { a = a, s = s, n = name } end
    end
    table.sort(out, function(x, y) if x.s ~= y.s then return x.s > y.s end return x.n < y.n end)
    local r = {}
    for i = 1, math.min(#out, 8) do
        local a = out[i].a
        r[i] = { title = a.name or a.id, sub = a.generic or a.comment or "", icon = a.icon or "application-x-executable",
                 act = function() if a.exec then pcall(sys.call, "apps.launch", a.exec) end end }
    end
    return r
end

-- súbory a priečinky: latte-hladaj (index + čerstvé súbory)
local function find_files(q, my)
    run("latte-hladaj", { "--json", "--max", "8", q }, function(out)
        if my ~= gen then return end
        local r = {}
        for _, l in ipairs(lines(out)) do
            local ok, f = pcall(json.decode, l)
            if ok and type(f) == "table" and f.path then
                local base = f.path:match("([^/]+)/*$") or f.path
                r[#r + 1] = { title = base .. (f.dir and "/" or ""), sub = f.path:match("^(.*)/[^/]*/*$") or "",
                              icon = f.dir and "folder" or "text-x-generic",
                              act = function()
                                  if f.dir then go("latte-app", { "subory", f.path }) else go("xdg-open", { f.path }) end
                                  go("latte-hladaj", { "--otvorene", f.path })
                              end }
            end
        end
        set_rows(r)
    end)
end

local function run_code(cmd)
    go("latte-terminal", { "sh", "-c", cmd .. '; exec "${SHELL:-/bin/bash}"' })     -- terminál po príkaze ostane otvorený
    clear()
end

-- AI: rozhovor cez latte-ai (nikdy neotvára prehliadač), odpoveď po riadkoch; v okne posledných 6 správ
local chat, busy = {}, false
local function paint_chat()
    local m, first = {}, math.max(1, #chat - 5)
    for i = first, #chat do m[#m + 1] = { who = chat[i].role == "user" and 0 or 1, txt = chat[i].content } end
    model.msgs = m
    fact.nmsgs = #m
    text.ai_status = busy and "…" or ""
end
local function ask_ai(t)
    if busy then return end
    chat[#chat + 1] = { role = "user", content = t }
    local msgs = {}
    for _, m in ipairs(chat) do msgs[#msgs + 1] = { role = m.role, content = m.content } end
    local answer = { role = "assistant", content = "…" }
    chat[#chat + 1] = answer
    busy = true
    fact.ai_open = 1
    paint_chat()
    local got = {}
    spawn("latte-ai", { "chat", json.encode(msgs) }, function(line)
        got[#got + 1] = line
        answer.content = table.concat(got, "\n")
        paint_chat()
    end, function()
        busy = false
        if #got == 0 then answer.content = tr("No answer (check Settings › AI)") end
        paint_chat()
    end)
end
on("ai_new", function() chat, busy = {}, false paint_chat() end)
on("ai_settings", function() go("latte-app", { "nastavenia", "ai" }) end)
on("ai_close", function() fact.ai_open = 0 end)

-- zmena textu: hľadá sa s krátkym oneskorením (aplikácie hneď, súbory po 250 ms)
local function search()
    local t = (text.q or ""):gsub("^%s+", "")
    fact.qempty = t == "" and 1 or 0
    confirm = nil
    gen = gen + 1
    local my = gen
    local id = MODES[mode].id
    if t == "" then set_rows({}) return end
    if id == "apps" then set_rows(find_apps(t))
    elseif id == "files" then
        if utf8.len(t) and utf8.len(t) >= 2 then after(250, function() if my == gen then find_files(t, my) end end) end
    elseif id == "code" then
        set_rows({ { title = tr("Run in console"), sub = t, icon = "utilities-terminal-symbolic", act = function() run_code(t) end } })
    else set_rows({}) end
end
on("text:q", search)

on("mode_next", function()
    mode = mode % #MODES + 1
    set_rows({})
    show_mode()
    search()                              -- hľadanie v novom režime
end)

on("q_clear", function() clear() fact.ai_open = 0 end)

-- Enter = prvý riadok; AI pošle text; príkaz: nebezpečný chce druhý Enter
on("q_submit", function()
    local t = (text.q or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then return end
    local id = MODES[mode].id
    if id == "ai" then ask_ai(t) text.q = "" return end
    if id == "code" then
        if dangerous(t) and confirm ~= t then
            confirm = t
            set_rows({ { title = tr("Dangerous command: press Enter again to run it"), sub = t, icon = "dialog-warning-symbolic" } })
            return
        end
        run_code(t)
        return
    end
    local r = rows[1]
    if r and r.act then r.act() clear() end
end)

on("res_go", function(i)
    local r = rows[(tonumber(i) or -1) + 1]
    if not r or not r.act then return end
    local id = MODES[mode].id
    if id == "code" then
        local t = (text.q or ""):gsub("^%s+", "")
        if dangerous(t) and confirm ~= t then confirm = t return end
    end
    r.act()
    clear()
end)
