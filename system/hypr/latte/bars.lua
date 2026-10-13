-- The same title bar with the same three buttons on every window that brings none of its own: minimise,
-- maximise, close, where Windows has them. The compositor draws them (the plugin hyprbars, built with
-- patches/hyprbars-latte.patch); apps that draw their own header (GTK, Firefox, Electron…) get no second one.
-- Without the plugin nothing here happens: a window is then moved with Win and the mouse, and closed from the
-- window bar or with Alt+F4.
local B = {}

B.plugin = (os.getenv("LATTE_PLUGINS") or "/usr/lib64/latteos") .. "/hyprbars.so"
-- classes of windows that draw their own header
local OWN_HEADER = "^(org\\.quickshell|xdg-desktop-portal.*|org\\.mozilla\\.firefox|firefox|chromium.*|google-chrome.*|brave.*|com\\.discordapp\\.Discord|discord|steam|"
    .. "com\\.valvesoftware\\.Steam|org\\.gnome\\..*|gnome-.*|code|Code|code-oss|electron.*|Spotify|spotify|obsidian|signal|"
    .. "org\\.signal\\.Signal|com\\.heroicgameslauncher\\.hgl|heroic|org\\.kde\\.kdenlive)$"

-- The cup the windows are made of (Settings › Coffee and cup, ~/.config/latteos/cup): the bar's colour and its text's,
-- as apps/common/Theme.qml has them for the apps of LatteOS.
local CUPS = { espresso = { "rgb(261d17)", "rgb(f3ebdd)" }, mocha = { "rgb(3e3027)", "rgb(f6eee2)" }, porcelain = { "rgb(ebe2d2)", "rgb(2a170c)" } }
-- "wallpaper": the colours skwd-wall works out of the wallpaper (bin/latte-wall), read from its palette
local function from_wallpaper()
    local f = io.open((os.getenv("XDG_CACHE_HOME") or ((os.getenv("HOME") or "") .. "/.cache")) .. "/skwd-wall-v2/colors.json", "r")
    if not f then return nil end
    local all = f:read("*a") or ""
    f:close()
    local function of(name) return all:match('"' .. name .. '"%s*:%s*"#(%x%x%x%x%x%x)"') end
    local bar, text = of("surfaceVariant"), of("surfaceText")
    -- the bar, its writing; then what the border of the window in front is made of, and of the others
    return bar and text and { "rgb(" .. bar .. ")", "rgb(" .. text .. ")", of("primary"), of("tertiary"), of("outline") } or nil
end
-- the border of windows for that cup: nil for the three cups of coffee, which keep the desktop's own
function B.border(name)
    local c = name == "wallpaper" and from_wallpaper() or nil
    if not c or not c[3] then return nil end
    return { active = { colors = { "rgb(" .. c[3] .. ")", "rgb(" .. (c[4] or c[3]) .. ")" }, angle = 45 }, inactive = "rgba(" .. (c[5] or "4a3b30") .. "66)" }
end
function B.cup(name)
    local c = name == "wallpaper" and (from_wallpaper() or CUPS.espresso) or CUPS[name]
    if not c or not (hl.plugin and hl.plugin.hyprbars) then return end
    hl.config({ plugin = { hyprbars = { bar_color = c[1] } } })
    -- the text's colour as a rule: a title already written is written again only when a rule says its colour changed
    hl.window_rule({ name = "latte-cup", match = { class = ".*" }, ["hyprbars:title_color"] = c[2] })
end

function B.setup(colors)
    local f = io.open(B.plugin, "r")
    if not f then return false end
    f:close()
    if not pcall(hl.plugin.load, B.plugin) or not (hl.plugin and hl.plugin.hyprbars) then return false end

    hl.config({ plugin = { hyprbars = {
        bar_height = 30,
        bar_color = "rgb(261d17)",
        ["col.text"] = "rgb(f3ebdd)",
        bar_text_font = "Inter",
        bar_text_size = 11,
        bar_text_weight = "semibold",
        bar_text_align = "left",
        bar_padding = 12,
        bar_button_padding = 8,
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        on_double_click = "hyprctl eval 'latte.win.maximize_active()'",
    } } })
    -- The right button on a title opens the window's menu, which is a card of the Goo scene. Only the plugin
    -- built with LatteOS's patch knows the setting.
    local known, value = pcall(hl.get_config, "plugin:hyprbars:on_right_click")
    if known and value ~= nil then
        hl.config({ plugin = { hyprbars = { on_right_click = [[latte-say "fact tap.x {x}" "fact tap.y {y}" "text win_asked {address}" "emit win_menu"]] } } })
    end
    -- from the edge inwards: close, maximise, minimise
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(c75b4a)", fg_color = "rgb(ffffff)", size = 17, icon = "✕", action = "hyprctl eval 'hl.dispatch(hl.dsp.window.close())'" })
    hl.plugin.hyprbars.add_button({ bg_color = colors.button, fg_color = "rgb(1e1712)", size = 17, icon = "□", action = "hyprctl eval 'latte.win.maximize_active()'" })
    hl.plugin.hyprbars.add_button({ bg_color = colors.button, fg_color = "rgb(1e1712)", size = 17, icon = "–", action = "hyprctl eval 'latte.win.minimize_active()'" })
    hl.window_rule({ name = "latte-own-header", match = { class = OWN_HEADER }, ["hyprbars:no_bar"] = true })
    return true
end

return B
