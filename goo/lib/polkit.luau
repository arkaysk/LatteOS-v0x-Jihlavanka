-- This scene runs from Hyprland's login session so Polkit can match it to graphical requests.
local M = {}
local memory_running = false
local pending = false

function M.start()
    local served, watch_error = pcall(sys.watch, "polkit", function(p)
        if type(p) ~= "table" then return end
        if p.ready == false then log("polkit · another program is this session's password dialog") end
        if p.pending then
            if not pending then
                fact.details = false
                text.details_label = tr("Show details")
            end
            pending = true
            fact.pending = true
            fact.asking = p.asking == true
            fact.wrong = p.error == "wrong"
            text.message = (type(p.message) == "string" and p.message ~= "") and p.message
                or (type(p.action) == "string" and p.action ~= "" and p.action)
                or tr("An application is requesting administrator approval.")
            text.action = type(p.action) == "string" and p.action or ""
            text.user = type(p.user) == "string" and p.user or ""
            text.prompt = type(p.prompt) == "string" and p.prompt or tr("Administrator password")
            text.info = type(p.info) == "string" and p.info or ""
            fact.has_user = text.user ~= ""
            fact.has_info = text.info ~= ""
        else
            pending = false
            fact.pending = false
            fact.asking = false
            fact.wrong = false
            text.password = ""
        end
    end)
    if not served then log("polkit · could not watch the service: " .. tostring(watch_error)) end

    on("authorize", function()
        if not fact.pending or not fact.asking then return end
        local answer = text.password or ""
        text.password = ""
        local ok, err = pcall(sys.call, "polkit.answer", answer)
        if not ok then log("polkit · could not send the answer: " .. tostring(err)) end
    end)
    on("dismiss", function()
        text.password = ""
        local ok, err = pcall(sys.call, "polkit.cancel")
        if not ok then log("polkit · could not cancel the request: " .. tostring(err)) end
    end)

    on("memory_request", function(id)
        if type(id) ~= "number" or id <= 0 or memory_running then return end
        memory_running = true
        text.memory_result = ""
        text.memory_status = string.format("%.0f:loading", id)
        local ok, err = pcall(run, "latte-devices", { "protected-memory" }, function(out)
            memory_running = false
            if type(out) == "string" and out ~= "" then
                text.memory_result = out
                text.memory_status = string.format("%.0f:ready", id)
            else
                text.memory_status = string.format("%.0f:error", id)
            end
        end)
        if not ok then
            memory_running = false
            log("polkit · memory request failed: " .. tostring(err))
            text.memory_status = string.format("%.0f:error", id)
        end
    end)

    on("details", function()
        fact.details = not fact.details
        text.details_label = tr(fact.details and "Hide details" or "Show details")
    end)
end

return M
