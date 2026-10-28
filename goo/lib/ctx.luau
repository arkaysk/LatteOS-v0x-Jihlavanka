-- The context menu (parts/ctx.plm): a classic menu at the pointer, on top of whatever is open. Rows are those of
-- a card, as far as a menu needs them:  { label, glyph, icon, danger, on, line, run, sub, keys }
--   keys  the keys that do the same, said on the right as a classic menu does ("Ctrl+C")
--   sub   rows of a submenu, which replaces this one in the same place and gets a row to go back
local icons = require("lib/icons")
local M = {}
M.keyed = false                              -- set while a key opens a menu (Ctrl+K in a card)

local MAX, ROW, RULE, PAD = 14, 36, 9, 12
local actions = {}

local function glyph(name) return name and (icons[name] or (name:byte(1) or 0) >= 128 and name) or "" end

function M.close()
    fact.ctx_open = false
    actions = {}
end
function M.is_open() return fact.ctx_open == true end

function M.open(rows, opts)
    opts = opts or {}
    local out, height = {}, PAD
    actions = {}
    for i, r in ipairs(rows) do
        if i > MAX then break end
        local rule = r.line == true and i > 1
        out[i] = { label = r.label or "", glyph = glyph(r.glyph), icon = r.icon or "", has_icon = (r.icon or "") ~= "",
                   danger = r.danger == true, on = r.on == true, line = rule, more = r.sub ~= nil,
                   keys = r.keys or "", keys_w = r.keys and (#r.keys * 7.5 + 12) or 0 }
        height = height + ROW + (rule and RULE or 0)
        actions[i - 1] = r
    end
    model.ctx = out
    fact.ctx_w = opts.width or 250
    fact.ctx_sel = (opts.keys or M.keyed) and 0 or -1     -- opened with the keys: its first row is chosen at once
    fact.ctx_h = height
    fact.ctx_open = #out > 0
    actions.back = opts.back
end

on("ctx_pick", function(i)
    local r = actions[i or -1]
    if not r then return end
    if r.sub then
        local back = actions
        local sub = { { label = tr("Back"), glyph = "chevron-left", sub_back = true } }
        for j, s in ipairs(r.sub) do
            local copy = table.clone(s)
            if j == 1 then copy.line = true end
            sub[#sub + 1] = copy
        end
        local rows_before = {}
        for k = 0, MAX - 1 do rows_before[#rows_before + 1] = back[k] end
        sub[1].run = function() M.open(rows_before, { width = fact.ctx_w }) end
        sub[1].keep = true
        M.open(sub, { width = fact.ctx_w })
        return
    end
    if r.keep then
        if r.run then r.run() end
        return
    end
    M.close()
    if r.run then after(60, r.run) end
end)
on("ctx_closed", function() M.close() end)

return M
