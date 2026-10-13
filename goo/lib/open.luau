-- Who opens what: the one place that names other programs, so that changing one of them is one line here.
-- A scene that uses this needs the program in its `permissions { run: … }`.
local M = {}

local TERMINAL = "foot"

local function go(cmd, args) run(cmd, args or {}, nil, { output = false }) end

function M.terminal() go(TERMINAL) end
-- a command in a terminal that stays open afterwards, in the user's shell
function M.shell(command) go(TERMINAL, { "sh", "-c", command .. '; exec "${SHELL:-/bin/bash}"' }) end
-- a program that needs a terminal to show itself; the window closes with it
function M.in_terminal(title, program) go(TERMINAL, { "-T", title, "-e", program }) end
-- a file or a folder with the app the user set for its kind; an address with the browser
function M.path(path) go("xdg-open", { path }) end
function M.url(url) go("xdg-open", { url }) end
-- LatteOS's own apps (bin/latte-app); `page`: where in the app to begin
function M.apps(page) go("latte-app", page and { "appmanager", page } or { "appmanager" }) end
function M.devices(page) go("latte-app", page and { "devices", page } or { "devices" }) end
function M.monitor(page) go("latte-app", page and { "monitor", page } or { "monitor" }) end
-- an app, as the `apps` service lists it
function M.app(a) if a and a.exec then pcall(sys.call, "apps.launch", a.exec) end end

return M
