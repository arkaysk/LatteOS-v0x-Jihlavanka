-- Which drop a window is born of (LATTEOS-GOO rule 14): the drop last pressed, or the one whose card was used,
-- if a window opens within a few seconds. Hyprland is told at once, so that it keeps that window clear until
-- the bubble has blown up to it (system/hypr/latte/windows.lua).
local M = {}
local place, at = -1, -100

function M.touch(k)
    if type(k) ~= "number" or k < 0 then return end
    place, at = k, os.time()
    run("hyprctl", { "eval", "latte.win.expect()" }, nil, { output = false })
end

-- the drop a window that has just come was born of, once; -1: none
function M.take()
    local was = place
    place = -1
    return os.time() - at <= 5 and was or -1
end

return M
