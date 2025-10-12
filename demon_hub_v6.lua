local req = syn and syn.request or request or http_request or http
local url = "https://pastebin.com/raw/cbBsFWLF"

if not req then
    warn("Your executor does not support HTTP requests!")
else
    local res = req({Url = url, Method = "GET"})
    if res and (res.Body or res.body) then
        local code = res.Body or res.body
        local f, err = loadstring(code)
        if f then
            local ok, execErr = pcall(f)
            if not ok then
                warn("Script runtime error:", execErr)
            end
        else
            warn("Loadstring failed:", err)
        end
    else
        warn("Failed to fetch script:", res)
    end
end
