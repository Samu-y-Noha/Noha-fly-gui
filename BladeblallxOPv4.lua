-- Wraith.exe AutoParry v4 - Polished GUI + Discord Integration (Dynamic Single-Ball AutoParry) - Part 1/4

-- Fluent UI & Managers
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Wraith.exe",
    SubTitle = "AutoParry v4",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Customization = Window:AddTab({ Title = "Customization", Icon = "sliders" }),
    Community = Window:AddTab({ Title = "Community", Icon = "users" })
}

-- Community Tab: Invite and Copy Link
Tabs.Community:AddParagraph({
    Title = "💬 Join the Discord!",
    Content = "Get support, updates, and chat with other users:\n\nhttps://discord.gg/utz7mspGVf"
})

Tabs.Community:AddButton({
    Title = "📋 Copy Invite to Clipboard",
    Description = "Click to copy the server invite link",
    Callback = function()
        setclipboard("https://discord.gg/utz7mspGVf")
        Fluent:Notify({
            Title = "Link Copied ✅",
            Content = "Invite copied to clipboard!",
            Duration = 3
        })
    end
})

-- Persistent Notification
Fluent:Notify({
    Title = "Join Our Discord 💬",
    Content = "https://discord.gg/utz7mspGVf",
    Duration = 0
})

-- Roblox Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- State Variables
local Player = Players.LocalPlayer
local MousePosition = Vector2.new(0, 0)

local autoParryEnabled = false
local rageModeEnabled = false
local parryDistanceThreshold = 40
local parryConn, parryChildConn
local ballData = {}  -- will hold data for the single ball

-- Anti-AFK
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

-- Mod Detector (kick if a mod joins)
local modList = { "AdminName1", "Moderator", "ModNameHere" }
Players.PlayerAdded:Connect(function(plr)
    for _, modName in ipairs(modList) do
        if plr.Name:lower() == modName:lower() then
            Player:Kick("Mod Detected: " .. plr.Name)
        end
    end
end)

-- Debug Overlay Setup
local function createDebugOverlay()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "ParryDebug"
    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(0, 300, 0, 24)
    label.Position = UDim2.new(1, -310, 0, 10)
    label.BackgroundTransparency = 0.4
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "Wraith.exe Active"
    return label
end

local debugLabel = createDebugOverlay()
-- Part 2 of 4 — Ball Tracker & AutoParry Logic with Dynamic Thresholds for a Single Ball

-- Function to Get the Ball from Workspace
local function GetBall()
    -- Since there's only one ball, assume it's a direct child of workspace.Balls.
    local folder = workspace:FindFirstChild("Balls")
    if folder then
        for _, b in ipairs(folder:GetChildren()) do
            if b:GetAttribute("realBall") then
                return b
            end
        end
    end
    return nil
end

-- Reset Parry Data
local function ResetParry()
    if parryConn then parryConn:Disconnect() end
    if parryChildConn then parryChildConn:Disconnect() end
    for _, data in pairs(ballData) do
        if data.parryConnAttr then data.parryConnAttr:Disconnect() end
    end
    ballData = {}
end

-- Bind Attribute Changes for the Ball (to detect when target changes)
local function bindParryAttr(ball)
    if not ballData[ball] then
        ballData[ball] = { IsParried = false, Cooldown = 0, TimeToHit = math.huge, parryConnAttr = nil }
    end
    if ballData[ball].parryConnAttr then
        ballData[ball].parryConnAttr:Disconnect()
    end
    ballData[ball].parryConnAttr = ball:GetAttributeChangedSignal("target"):Connect(function()
        -- When target changes, you might want to allow a new parry;
        ballData[ball].IsParried = false
        ballData[ball].Cooldown = 0
        ballData[ball].TimeToHit = math.huge
    end)
end

-- AutoParry Main Loop with Dynamic Time-to-Hit Calculation and a Short Cooldown
local function setupParry()
    ResetParry()
    local ball = GetBall()
    if ball then
        bindParryAttr(ball)
    end

    parryChildConn = workspace.Balls.ChildAdded:Connect(function(child)
        if autoParryEnabled and child:GetAttribute("realBall") then
            bindParryAttr(child)
        end
    end)

    parryConn = RunService.Heartbeat:Connect(function()
        if not autoParryEnabled then return end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local ball = GetBall()
        if not ball or not ball:FindFirstChild("zoomies") or ball.Anchored then
            debugLabel.Text = "No ball detected"
            return
        end

        bindParryAttr(ball)
        local data = ballData[ball]
        local pos = ball.Position
        local vel = ball.zoomies.VectorVelocity
        local dist = (hrp.Position - pos).Magnitude

        if vel.Magnitude >= 0.5 and dist <= parryDistanceThreshold then
            local forwardDist = (hrp.Position - pos):Dot(vel.Unit)
            local tth = forwardDist / vel.Magnitude
            data.TimeToHit = tth

            -- Dynamic TTH thresholds based on ball speed adjustments:
            local baseSpeed = 50    -- "Normal" speed reference
            local baseLower = 0.1   -- Base lower TTH threshold
            local baseUpper = 0.8   -- Base upper TTH threshold
            local speedFactor = baseSpeed / math.max(vel.Magnitude, baseSpeed)
            local lowerTTH = baseLower * speedFactor
            local upperTTH = baseUpper * speedFactor

            if ball:GetAttribute("target") == Player.Name and (not data.IsParried) and tth >= lowerTTH and tth <= upperTTH then
                VirtualInputManager:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, false, game, 0)
                data.IsParried = true  -- Parry this collision
                data.Cooldown = tick()
                debugLabel.Text = "🎯 Parried: " .. ball.Name
            end
        else
            debugLabel.Text = "No threat detected"
        end

        -- Reset the parry flag after a cooldown so that the same ball can be parried again
        for _, d in pairs(ballData) do
            if tick() - d.Cooldown >= 0.3 then  -- 0.3 sec cooldown (adjust as needed)
                d.IsParried = false
            end
        end

        -- Optional Rage Mode: for very fast ball threats at close range
        if rageModeEnabled then
            local ball = GetBall()
            if ball and ball:FindFirstChild("zoomies") and (not ballData[ball].IsParried) then
                local pos = ball.Position
                local vel = ball.zoomies.VectorVelocity
                local dist = (hrp.Position - pos).Magnitude
                if vel.Magnitude >= 50 and dist <= 15 and ball:GetAttribute("target") == Player.Name then
                    VirtualInputManager:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, false, game, 0)
                    ballData[ball].IsParried = true
                    ballData[ball].Cooldown = tick()
                    debugLabel.Text = "💢 Rage Parry: " .. ball.Name
                end
            end
        end
    end)
end

-- Mouse Position Tracking
UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then
        MousePosition = i.Position
    end
end)
-- Part 3 of 4 — GUI Toggles and Sliders

-- Toggle to enable/disable AutoParry
Tabs.Main:AddToggle("AutoParry", {
    Title = "Enable Auto Parry",
    Default = false
}):OnChanged(function(val)
    autoParryEnabled = val
    if val then
        setupParry()
    else
        ResetParry()
        debugLabel.Text = "AutoParry Disabled"
    end
end)

-- Toggle for Rage Mode
Tabs.Main:AddToggle("RageMode", {
    Title = "💢 Rage Parry Mode",
    Default = false
}):OnChanged(function(val)
    rageModeEnabled = val
    debugLabel.Text = val and "Rage Mode Enabled" or "Rage Mode Disabled"
end)

-- Toggle for FPS Booster that reduces visual effects
local function activateFPSBooster()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        if Lighting then
            Lighting.GlobalShadows = false
            Lighting.Technology = Enum.Technology.Compatibility
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            end
        end
        debugLabel.Text = "FPS Booster Activated"
    end)
end

Tabs.Main:AddToggle("FPSBooster", {
    Title = "Activate FPS Booster",
    Default = false
}):OnChanged(function(val)
    if val then
        activateFPSBooster()
    else
        debugLabel.Text = "FPS Booster Disabled"
    end
end)

-- Slider to control the parry distance threshold (in studs)
Tabs.Customization:AddSlider("ParryDistance", {
    Title = "AutoParry Distance (Studs)",
    Description = "Only parry when the ball is within this distance",
    Default = parryDistanceThreshold,
    Min = 10,
    Max = 100,
    Rounding = 0
}):OnChanged(function(val)
    parryDistanceThreshold = val
    debugLabel.Text = "Parry Distance set to " .. val
end)
-- Part 4 of 4 — Performance HUD & SaveManager Integration

-- Optional Overlays: FPS Counter and Ball Speed Monitoring
local SHOW_FPS = false
local SHOW_BALL_SPEED = false

Tabs.Customization:AddToggle("ShowFPS", {
    Title = "Show FPS Counter",
    Default = false
}):OnChanged(function(val)
    SHOW_FPS = val
end)

Tabs.Customization:AddToggle("ShowBallSpeed", {
    Title = "Measure Ball Speed",
    Default = false
}):OnChanged(function(val)
    SHOW_BALL_SPEED = val
end)

-- Create a Performance HUD
local perfGui = Instance.new("ScreenGui", CoreGui)
perfGui.Name = "PerfMetrics"
perfGui.Enabled = false

local fpsLabel = Instance.new("TextLabel", perfGui)
fpsLabel.Size = UDim2.new(0, 200, 0, 30)
fpsLabel.Position = UDim2.new(0, 10, 0, 10)
fpsLabel.BackgroundTransparency = 0.5
fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fpsLabel.TextColor3 = Color3.new(1, 1, 1)
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextSize = 20
fpsLabel.Text = "FPS: N/A"

local ballSpeedLabel = Instance.new("TextLabel", perfGui)
ballSpeedLabel.Size = UDim2.new(0, 300, 0, 30)
ballSpeedLabel.Position = UDim2.new(0, 10, 0, 50)
ballSpeedLabel.BackgroundTransparency = 0.5
ballSpeedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ballSpeedLabel.TextColor3 = Color3.new(1, 1, 1)
ballSpeedLabel.Font = Enum.Font.SourceSansBold
ballSpeedLabel.TextSize = 20
ballSpeedLabel.Text = "Max Ball Speed: N/A"

perfGui.Parent = CoreGui

RunService.Heartbeat:Connect(function()
    perfGui.Enabled = SHOW_FPS or SHOW_BALL_SPEED
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    if SHOW_FPS then
        fpsLabel.Text = "FPS: " .. fps
    end
    if SHOW_BALL_SPEED then
        local ball = GetBall()
        local maxSpeed = 0
        if ball and ball:FindFirstChild("zoomies") then
            local spd = ball.zoomies.VectorVelocity.Magnitude
            maxSpeed = spd
        end
        ballSpeedLabel.Text = "Max Ball Speed: " .. string.format("%.2f", maxSpeed)
    end
end)

-- Save and Load Configuration Sections
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("Wraith")
SaveManager:SetFolder("Wraith/BladeBallPro")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({
    Title = "Wraith.exe",
    Content = "AutoParry Script Loaded ✔️",
    Duration = 3
})
SaveManager:LoadAutoloadConfig()
