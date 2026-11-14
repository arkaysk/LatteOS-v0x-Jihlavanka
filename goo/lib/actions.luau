-- LensShore's Actions panel (6B.47, Raycast's Ctrl+K): a small list over the panel's foot with the chosen row's actions,
-- a search field at its top, the arrows and Enter, Esc closing only the panel. It takes what the card offers the right
-- button (rows as parts/ctx.plm has them: { label, glyph, danger, line, run, sub, keys }): while the card is LensShore's
-- panel and a key asked for it (ctx.keyed), `ctx.open` lands here; the right button keeps the classic menu.
local icons = require("lib/icons")
local ctx = require("lib/ctx")
local M = { FOOT = 36 }
local MAX, ROW, RULE, TOP = 8, 34, 9, 52
local all, shown = {}, {}

local function refresh()
    local q = (text.ap_q or ""):lower()
    local out, rows, h = {}, {}, 0
    for _, r in ipairs(all) do
        if q == "" or (r.label or ""):lower():find(q, 1, true) then rows[#rows + 1] = r end
    end
    shown = {}
    for i, r in ipairs(rows) do
        if i > MAX then break end
        local rule = q == "" and r.line == true and i > 1
        local g = r.glyph and (icons[r.glyph] or ((r.glyph:byte(1) or 0) >= 128 and r.glyph)) or ""
        out[i] = { label = r.label or "", glyph = g, danger = r.danger == true, line = rule, keys = r.keys or "", more = r.sub ~= nil }
        h = h + ROW + (rule and RULE or 0)
        shown[i] = r
    end
    model.ap = out
    fact.ap_h = TOP + math.max(h, ROW) + 8
    fact.ap_sel, fact.ap_typed = 0, q ~= ""
    text.ap_none = #out == 0 and tr("No actions") or ""
end

function M.close()
    if not fact.ap_open then return end
    fact.ap_open = false
    focus("lens_q")
end
function M.open(rows)
    all, text.ap_q = rows, ""
    refresh()
    fact.ap_open = true
    focus("ap_q")
end
function M.install()
    local base = ctx.open
    ctx.open = function(rows, opts)
        if ctx.keyed and fact.card_lens then return M.open(rows) end
        return base(rows, opts)
    end
end
M.install()

on("text:ap_q", function() if fact.ap_open then refresh() end end)
on("ap_pick", function(i)
    local r = shown[(i or -1) + 1]
    if not r then return end
    if r.sub then
        local back = all
        local sub = { { label = tr("Back"), glyph = "chevron-left", keep = true, run = function() M.open(back) end } }
        for j, s in ipairs(r.sub) do local c = table.clone(s) if j == 1 then c.line = true end sub[#sub + 1] = c end
        M.open(sub)
        return
    end
    M.close()
    if r.run then after(60, r.run) end
end)
on("ap_close", M.close)
-- a press anywhere else, or the card going away, closes it
on("fact:card_open", function() if not fact.card_open then fact.ap_open = false end end)

return M
