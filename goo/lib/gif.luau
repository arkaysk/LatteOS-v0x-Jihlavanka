-- LensShore's GIFs (Emoji › GIF, 6B.28), as Raycast's GIF Search: what is trending, or what is typed, from the service
-- and with the key the user chose (Settings › Drops › LensShore: Giphy unless another; bin/latte-gif), in pages of
-- large pictures turned to the side; favourites and the ones used lately. A press pastes the GIF itself where one was
-- typing; the right button copies it, its link or Markdown, opens its page, keeps it as a favourite.
local ctx = require("lib/ctx")
local M = {}
local function N(s) return s end

local NAMES = { giphy = "Giphy", tenor = "Tenor", klipy = "Klipy" }
local st = { view = "trending", page = 1, query = nil, got = nil, asked = nil, busy = false }

local function source(env) local s = env.settings.lens_gif_source return NAMES[s] and s or "giphy" end
local function key(env) return env.settings["lens_gif_key_" .. source(env)] or "" end
local function favs(env) env.kept.gif_favs = env.kept.gif_favs or {} return env.kept.gif_favs end
local function recent(env) env.kept.gif_recent = env.kept.gif_recent or {} return env.kept.gif_recent end

-- the page asked of the service; drawn again when it comes
local function ask(env, q, page)
    local want = source(env) .. "\1" .. q .. "\1" .. page
    if st.asked == want then return end
    st.asked, st.busy = want, true
    run("latte-gif", { "search", source(env), q, tostring(page) }, function(out)
        if st.asked ~= want then return end
        local ok, r = pcall(json.decode, out or "")
        st.got, st.busy = (ok and type(r) == "table") and r or { items = {}, error = "?" }, false
        env.render(true)
    end, { env = { LATTE_GIF_KEY = key(env) } })
end

local function remember(g, env)
    local list = recent(env)
    for i = #list, 1, -1 do if list[i].id == g.id then table.remove(list, i) end end
    table.insert(list, 1, g)
    while #list > 24 do table.remove(list) end
    env.save()
end
-- the GIF itself onto the clipboard, as a picture (the service's whole file, downloaded once)
local function put_gif(g, env)
    return function(done)
        run("latte-gif", { "get", g.source or source(env), g.id, g.full }, function(out)
            local path = (out or ""):gsub("%s+$", "")
            if path == "" then return done() end
            run("wl-copy", { "--type", "image/gif" }, function() done() end, { stdin = path, output = false })
        end)
    end
end
local function paste(g, env) remember(g, env) env.paste_with(put_gif(g, env)) end
local function copy(g, env) remember(g, env) put_gif(g, env)(function() end) end

local function actions(g, env)
    local f = favs(env)
    local at
    for i, x in ipairs(f) do if x.id == g.id then at = i end end
    return {
        { label = tr("Paste the GIF"), glyph = "clipboard", keys = "↵", run = function() env.close() paste(g, env) end },
        { label = tr("Copy the GIF"), glyph = "copy", keys = "Ctrl+↵", run = function() env.close() copy(g, env) end },
        { label = tr("Copy the link"), glyph = "link", line = true, run = function() env.close() env.copy(g.full) end },
        { label = tr("Copy as Markdown"), glyph = "code", run = function() env.close() env.copy("![" .. (g.title or "") .. "](" .. g.full .. ")") end },
        { label = tr("Open in the browser"), glyph = "world", run = function() env.close() env.open_url(g.page ~= "" and g.page or g.full) end },
        { label = at and tr("Remove from favourites") or tr("Add to favourites"), glyph = "star", keys = "Ctrl+.", line = true,
          run = function() if at then table.remove(f, at) else f[#f + 1] = g end env.save() env.render(true) end },
    }
end

function M.sections(q, env)
    local out = {}
    if key(env) == "" then
        out[#out + 1] = { { label = (tr("GIFs come from {source}: put in its key in the Settings"):gsub("{source}", NAMES[source(env)])),
                            glyph = "key", run = env.open_settings } }
        return out
    end
    if q ~= st.query then st.query, st.page = q, 1 end
    local items, more, err = {}, false, nil
    if q == "" and st.view ~= "trending" then
        local list = st.view == "favs" and favs(env) or recent(env)
        local from = (st.page - 1) * 8
        for i = from + 1, math.min(from + 8, #list) do items[#items + 1] = list[i] end
        more = #list > from + 8
    else
        ask(env, q, st.page)
        local got = st.got
        if got and st.asked == source(env) .. "\1" .. q .. "\1" .. st.page then
            items, more = got.items or {}, got.more == true
            if (got.error or "") ~= "" then err = got.error end
            for _, g in ipairs(items) do g.source = source(env) end
        end
    end
    local view_name = q ~= "" and tr(N("Results")) or st.view == "favs" and tr(N("Favourites")) or st.view == "recent" and tr(N("Recently used")) or tr(N("Trending"))
    local function turn(d) return function() st.page = math.max(1, st.page + d) env.render(true) end end
    out[#out + 1] = { { pills = {
        { label = "‹", keep = true, skip = true, off = st.page <= 1, run = turn(-1) },
        { label = NAMES[source(env)] .. " · " .. view_name .. "  " .. st.page, glyph = "chevron-down", keep = true, skip = true, run = function()
            local function pick(v) return function() st.view, st.page = v, 1 env.set_text("") env.render(true) end end
            ctx.open({ { label = tr(N("Trending")), glyph = "flame", on = st.view == "trending", run = pick("trending") },
                       { label = tr(N("Favourites")), glyph = "star", on = st.view == "favs", run = pick("favs") },
                       { label = tr(N("Recently used")), glyph = "clock", on = st.view == "recent", run = pick("recent") } }, { width = 240 })
        end },
        { label = "›", keep = true, skip = true, off = not more, run = turn(1) },
    }, per = 3, line = true } }
    if err then
        out[#out + 1] = { { label = err == "key" and tr(N("The key was not accepted")) or (tr("{source} did not answer"):gsub("{source}", NAMES[source(env)])),
                            line2 = err ~= "key" and err or "", glyph = "alert-triangle", run = env.open_settings } }
        return out
    end
    if #items == 0 then
        out[#out + 1] = { { label = tr(st.busy and N("Searching…") or N("Nothing here yet")), glyph = "gif", quiet = true } }
        return out
    end
    local cells, f = {}, favs(env)
    for i, g in ipairs(items) do
        local fav = false
        for _, x in ipairs(f) do if x.id == g.id then fav = true end end
        cells[i] = { label = g.title ~= "" and g.title or "GIF", icon = g.preview, on = fav, main = tr("Paste the GIF"), first = i == 1, gif = g,
                     run = function() paste(g, env) end, right = function() ctx.open(actions(g, env), { width = 280 }) end }
    end
    out[#out + 1] = { { head = true, label = (tr("SEARCHED AT {source}: WHAT YOU TYPE GOES THERE"):gsub("{source}", NAMES[source(env)]:upper())) }, { cells = cells, per = 4, big = true } }
    return out
end

-- the keys: Ctrl+Enter copies, Ctrl+. a favourite, Page Down and Up the pages
function M.combo(n, it, env)
    local g = it and it.gif
    if n == 1 and g then env.close() copy(g, env)
    elseif n == 2 and g then
        local f = favs(env)
        local at
        for i, x in ipairs(f) do if x.id == g.id then at = i end end
        if at then table.remove(f, at) else f[#f + 1] = g end
        env.save() env.render(true)
    elseif n == 7 or n == 8 then st.page = math.max(1, st.page + (n == 7 and 1 or -1)) env.render(true) end
end

return M
