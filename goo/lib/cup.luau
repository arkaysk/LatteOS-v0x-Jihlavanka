-- The colours of LatteOS's windows for a window made with pleamar (goo/props.plm, templates/okno-vedlajsie): the cup
-- the user chose for the windows, as apps/common/Theme.qml chooses it — a word in ~/.config/latteos/cup, one of
-- LatteOS's one list of cups (system/cups.json), or "wallpaper", the colours skwd-wall works out of the wallpaper. The scene declares
-- `fact c.K.r/g/b` for K 0…9 (ground, surface, card, raised, line, cream, dim, faint, gold, coffee) and `fact light`;
-- its `permissions { run: "cat"; services: "env" }`.
local M = {}

local function rgb(hex)
    hex = (hex or ""):gsub("^#", "")
    return (tonumber(hex:sub(1, 2), 16) or 128) / 255, (tonumber(hex:sub(3, 4), 16) or 128) / 255, (tonumber(hex:sub(5, 6), 16) or 128) / 255
end
local function paint(list)
    for k, hex in ipairs(list) do
        local r, g, b = rgb(hex)
        fact["c." .. (k - 1) .. ".r"], fact["c." .. (k - 1) .. ".g"], fact["c." .. (k - 1) .. ".b"] = r, g, b
    end
end
local function mix(a, b, t)
    local ar, ag, ab = rgb(a); local br, bg, bb = rgb(b)
    return string.format("#%02x%02x%02x", math.floor((ar + (br - ar) * t) * 255), math.floor((ag + (bg - ag) * t) * 255), math.floor((ab + (bb - ab) * t) * 255))
end

function M.start()
    local okh, home = pcall(sys.ask, "env", "HOME")
    home = okh and home or ""
    local okc, conf = pcall(sys.ask, "env", "XDG_CONFIG_HOME"); conf = (okc and conf ~= "" and conf) or (home .. "/.config")
    local okk, cache = pcall(sys.ask, "env", "XDG_CACHE_HOME"); cache = (okk and cache ~= "" and cache) or (home .. "/.cache")
    local oks, share = pcall(sys.ask, "env", "LATTE_SHARE"); share = (oks and share ~= "" and share) or "/usr/share/latteos"
    local KEYS = { "ground", "surface", "card", "raised", "line", "cream", "dim", "faint", "gold", "coffee" }
    run("cat", { share .. "/cups.json" }, function(list)
        local ok, cups = pcall(json.decode, list or "")
        cups = ok and type(cups) == "table" and cups or {}
        local function of(c) local out = {}; for i, k in ipairs(KEYS) do out[i] = c[k] end; return out end
        if cups.espresso then paint(of(cups.espresso)) end
        run("cat", { conf .. "/latteos/cup" }, function(word)
            word = (word or ""):match("^%s*(%S*)") or ""
            local c = type(cups[word]) == "table" and cups[word] or nil
            fact.light = c ~= nil and c.light == true
            if c then paint(of(c)); return end
            if word ~= "wallpaper" then return end
        run("cat", { cache .. "/skwd-wall-v2/colors.json" }, function(out)
            local ok, c = pcall(json.decode, out or "")
            if not ok or type(c) ~= "table" then return end
            paint({ c.background, c.surface, c.surfaceVariant, c.surfaceContainer, mix(c.surfaceContainer, c.outline, 0.35),
                    c.surfaceText, mix(c.surfaceText, c.outline, 0.6), c.outline, c.primary, c.tertiary })
        end)
        end)
    end)
end

return M
