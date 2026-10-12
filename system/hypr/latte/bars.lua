-- The same title bar with the same three buttons on every window that brings none of its own: minimise,
-- maximise, close, where Windows has them. The compositor draws them (the plugin hyprbars, built with
-- patches/hyprbars-latte.patch); apps that draw their own header (GTK, Firefox, Electron…) get no second one.
-- Without the plugin nothing here happens: a window is then moved with Win and the mouse, and closed from the
-- window bar or with Alt+F4.
local B = {}

B.plugin = "/usr/lib64/latteos/hyprbars.so"
-- classes of windows that draw their own header
local OWN_HEADER = "^(org\\.mozilla\\.firefox|firefox|chromium.*|google-chrome.*|brave.*|com\\.discordapp\\.Discord|discord|steam|"
    .. "com\\.valvesoftware\\.Steam|org\\.gnome\\..*|gnome-.*|code|Code|code-oss|electron.*|Spotify|spotify|obsidian|signal|"
    .. "org\\.signal\\.Signal|com\\.heroicgameslauncher\\.hgl|heroic|org\\.kde\\.kdenlive)$"

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
        hl.config({ plugin = { hyprbars = { on_right_click = [[pleamar --say goo "fact tap.x {x}" "fact tap.y {y}" "text win_asked {address}" "emit win_menu"]] } } })
    end
    -- from the edge inwards: close, maximise, minimise
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(c75b4a)", fg_color = "rgb(ffffff)", size = 17, icon = "✕", action = "hyprctl eval 'hl.dispatch(hl.dsp.window.close())'" })
    hl.plugin.hyprbars.add_button({ bg_color = colors.button, fg_color = "rgb(1e1712)", size = 17, icon = "□", action = "hyprctl eval 'latte.win.maximize_active()'" })
    hl.plugin.hyprbars.add_button({ bg_color = colors.button, fg_color = "rgb(1e1712)", size = 17, icon = "–", action = "hyprctl eval 'latte.win.minimize_active()'" })
    hl.window_rule({ name = "latte-own-header", match = { class = OWN_HEADER }, ["hyprbars:no_bar"] = true })
    return true
end

return B
