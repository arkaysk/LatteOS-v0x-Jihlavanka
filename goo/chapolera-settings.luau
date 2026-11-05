local saved = nil
local now = nil

local function copy_settings(value)
    return { automatic = value.automatic, preview_limit = value.preview_limit }
end

local function show()
    if not now then return end
    fact.o_mode = now.automatic and 0 or 1
    fact.o_limit = now.preview_limit
    text.o_count = tr("{n} previews at once", { n = now.preview_limit })
    fact.o_dirty = now.automatic ~= saved.automatic or now.preview_limit ~= saved.preview_limit
end

local function read_memory()
    if not now or not now.automatic then return end
    run("latte-chapolera", { "memory" }, function(out, code)
        if code ~= 0 then
            text.o_auto_text = tr("Available memory could not be measured; using the smallest preview count.")
            return
        end
        local ok, value = pcall(json.decode, out or "")
        local bytes = ok and type(value) == "table" and tonumber(value.available_bytes) or nil
        if not bytes or bytes < 0 then
            text.o_auto_text = tr("Available memory could not be measured; using the smallest preview count.")
            return
        end
        local limit = tonumber(value.preview_limit)
        if limit ~= 8 and limit ~= 12 and limit ~= 24 and limit ~= 48 then
            text.o_auto_text = tr("Available memory could not be measured; using the smallest preview count.")
            return
        end
        local gib = 1024 * 1024 * 1024
        text.o_auto_text = tr("Automatic: {n} previews · {memory} GiB available", {
            n = limit,
            memory = string.format("%.1f", bytes / gib):gsub("%.", ","),
        })
    end)
end

local function read()
    run("latte-chapolera", { "settings" }, function(out, code)
        if code ~= 0 then
            text.o_error = tr("Could not load Chapolera settings.")
            fact.o_has_error = true
            return
        end
        local ok, value = pcall(json.decode, out or "")
        if not ok or type(value) ~= "table" or type(value.automatic) ~= "boolean"
                or type(value.preview_limit) ~= "number" or value.preview_limit < 8
                or value.preview_limit > 96 or (value.preview_limit - 8) % 4 ~= 0 then
            text.o_error = tr("Chapolera settings are invalid.")
            fact.o_has_error = true
            return
        end
        saved = copy_settings(value)
        now = copy_settings(value)
        text.o_error = ""
        fact.o_has_error = false
        show()
        read_memory()
    end)
end

local function write(after_)
    if not now or fact.o_saving then return end
    fact.o_saving = true
    text.o_error = ""
    fact.o_has_error = false
    run("latte-chapolera", {
        "settings-set",
        now.automatic and "automatic" or "manual",
        tostring(now.preview_limit),
    }, function(out, code)
        fact.o_saving = false
        if code ~= 0 then
            text.o_error = tr("Could not save Chapolera settings.")
            fact.o_has_error = true
            return
        end
        local ok, value = pcall(json.decode, out or "")
        if not ok or type(value) ~= "table" or type(value.automatic) ~= "boolean"
                or type(value.preview_limit) ~= "number" then
            text.o_error = tr("Saved settings could not be verified.")
            fact.o_has_error = true
            return
        end
        saved = copy_settings(value)
        now = copy_settings(value)
        show()
        if after_ then after_() end
    end)
end

on("mode_pick", function(mode)
    if not now then return end
    now.automatic = tonumber(mode) == 0
    text.o_error = ""
    fact.o_has_error = false
    show()
    read_memory()
end)

on("preview_pick", function(position)
    if not now or now.automatic then return end
    position = math.max(0, math.min(1, tonumber(position) or 0))
    now.preview_limit = 8 + math.floor(position * 22 + 0.5) * 4
    text.o_error = ""
    fact.o_has_error = false
    show()
end)

on("apply", function() write() end)
on("ok", function() write(function() emit("done") end) end)

require("lib/cup").start()
text.o_title = tr("Chapolera settings")
text.o_close = tr("Close")
text.o_auto = tr("Automatic")
text.o_manual = tr("Manual")
text.o_slider_label = tr("Number of previews")
text.o_ok = tr("OK")
text.o_cancel = tr("Cancel")
text.o_apply = tr("Apply")
text.o_move = tr("Move the window")
text.o_auto_hint = tr("Available memory determines how many previews are kept on screen at once.")
text.o_manual_hint = tr("Only the number visible at once changes; every file remains available on later pages.")
every(10000, read_memory)
read()
