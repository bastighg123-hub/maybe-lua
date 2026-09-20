--// COMBINED MENU — RAGEBOT • FOV • WORLD • VISUALS • SETTINGS
--// LocalScript -> StarterPlayer > StarterPlayerScripts
--// Dark purple tab-style UI
--// Added: Custom Menu Keybind (Default: RightShift)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- COLORS
--==================================================

local BG = Color3.fromRGB(25, 18, 55)
local BG2 = Color3.fromRGB(31, 22, 68)
local PANEL = Color3.fromRGB(38, 27, 78)
local PANEL2 = Color3.fromRGB(44, 31, 88)
local BORDER = Color3.fromRGB(78, 52, 125)
local TEXT = Color3.fromRGB(240, 235, 255)
local SUBTEXT = Color3.fromRGB(175, 165, 205)
local ACCENT = Color3.fromRGB(170, 40, 125)
local ACCENT2 = Color3.fromRGB(105, 45, 160)
local ON_COLOR = Color3.fromRGB(55, 205, 105)
local OFF_COLOR = Color3.fromRGB(145, 45, 75)

--==================================================
-- STATE
--==================================================

local menuOpen = true
local currentTab = "RAGEBOT"

-- CUSTOM MENU KEYBIND
local menuKeybind = Enum.KeyCode.RightShift
local waitingForKeybind = false

local rageEnabled = false
local nearestEnabled = false
local fastMeleeEnabled = false

local spinEnabled = false
local spinSpeed = 5

local flickbotEnabled = false
local flickAngle = 90
local flickInterval = 0.08
local flickTimer = 0

local spoofersEnabled = false

local tpLoopEnabled = false
local tpDistance = 100
local tpInterval = 0.001
local tpUpOffset = 0
local tpYRotation = 90

local tpTimer = 0
local tpPhase = false
local tpReturnCFrame = nil

local yOffsetEnabled = false
local yOffset = -7

local randomYOffsetEnabled = false
local randomYOffsetTimer = 0
local randomYOffsetInterval = 0.1

local lockedY = nil
local lastPos = nil

local unlockAllEnabled = false

--==================================================
-- FOV STATE
--==================================================

local fovEnabled = false
local fovFillEnabled = true
local fovBorderEnabled = true
local fovRotationEnabled = true
local rainbowEnabled = false

local fovSize = 240
local rotationSpeed = 90

local fillTransparency = 0.55
local borderTransparency = 0.1
local borderThickness = 2

local ringColor = Color3.fromRGB(0, 170, 255)

local hue = 210
local saturation = 100
local brightness = 100

--==================================================
-- WORLD STATE
--==================================================

local nightMode = false
local galaxyMode = false
local fullbright = false

--==================================================
-- VISUAL STATE
--==================================================

local blurEnabled = false
local colorCorrectionEnabled = false

--==================================================
-- UI COLOR STATE
--==================================================

local uiHue = 270
local uiSaturation = 70
local uiBrightness = 35

--==================================================
-- CONFIG STATE
--==================================================

local configs = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil
}

local selectedConfig = 1

--==================================================
-- FAST MELEE
--==================================================

local OriginalMeleeValues = {}

local cooldownFields = {
    "Cooldown",
    "AttackCooldown",
    "UseDelay",
    "SpinCooldown",
    "HeavyAttackCooldown",
    "AbilityCooldown",
    "FireCooldown",
    "DashCooldown"
}

local function getItemLibrary()
    local modules = ReplicatedStorage:FindFirstChild("Modules")

    if not modules then
        return nil
    end

    local itemLib = modules:FindFirstChild("ItemLibrary")

    if not itemLib then
        return nil
    end

    local success, library = pcall(require, itemLib)

    if not success or type(library) ~= "table" then
        return nil
    end

    return library
end

local function setFastMelee(enabled)
    local library = getItemLibrary()

    if not library then
        return
    end

    local categories = {
        library.Items,
        library.Weapons,
        library.Melee,
        library.Primary,
        library.Secondary,
        library.Utility
    }

    for _, items in ipairs(categories) do
        if type(items) == "table" then
            for _, item in pairs(items) do
                if type(item) == "table" then

                    if not OriginalMeleeValues[item] then
                        OriginalMeleeValues[item] = {}

                        for _, field in ipairs(cooldownFields) do
                            if item[field] ~= nil then
                                OriginalMeleeValues[item][field] = item[field]
                            end
                        end
                    end

                    if enabled then
                        for _, field in ipairs(cooldownFields) do
                            if item[field] ~= nil then
                                pcall(function()
                                    item[field] = 0
                                end)
                            end
                        end
                    else
                        local original = OriginalMeleeValues[item]

                        if original then
                            for field, value in pairs(original) do
                                pcall(function()
                                    item[field] = value
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

--==================================================
-- OWN-GAME UNLOCK ALL
--==================================================

local function setUnlockAll(enabled)
    unlockAllEnabled = enabled

    if enabled then
        print("Unlock All: ON")
    else
        print("Unlock All: OFF")
    end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "CombinedMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

--==================================================
-- FOV
--==================================================

local fov = Instance.new("Frame")
fov.Name = "FOVCircle"
fov.AnchorPoint = Vector2.new(0.5, 0.5)
fov.Position = UDim2.fromScale(0.5, 0.5)
fov.Size = UDim2.fromOffset(fovSize, fovSize)
fov.BackgroundTransparency = 1
fov.BorderSizePixel = 0
fov.Visible = false
fov.ZIndex = 2
fov.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fov

local fovFill = Instance.new("Frame")
fovFill.AnchorPoint = Vector2.new(0.5, 0.5)
fovFill.Position = UDim2.fromScale(0.5, 0.5)
fovFill.Size = UDim2.fromScale(1, 1)
fovFill.BackgroundColor3 = ringColor
fovFill.BackgroundTransparency = fillTransparency
fovFill.BorderSizePixel = 0
fovFill.ZIndex = 2
fovFill.Parent = fov

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fovFill

local fovGradient = Instance.new("UIGradient")
fovGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, ringColor),
    ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(1, ringColor)
})
fovGradient.Parent = fovFill

local fovBorder = Instance.new("UIStroke")
fovBorder.Color = ringColor
fovBorder.Thickness = borderThickness
fovBorder.Transparency = borderTransparency
fovBorder.Parent = fov

local function updateFOV()
    fov.Size = UDim2.fromOffset(fovSize, fovSize)

    fovFill.Visible = fovFillEnabled
    fovFill.BackgroundColor3 = ringColor
    fovFill.BackgroundTransparency = fillTransparency

    fovBorder.Enabled = fovBorderEnabled
    fovBorder.Color = ringColor
    fovBorder.Thickness = borderThickness
    fovBorder.Transparency = borderTransparency

    fovGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ringColor),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, ringColor)
    })
end

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(570, 520)
main.Position = UDim2.fromOffset(250, 180)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = BORDER
mainStroke.Thickness = 2
mainStroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = BG2
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(1, -24, 1, 0)
title.Font = Enum.Font.Code
title.Text = "CONTROL MENU  —  BETA EDITION"
title.TextColor3 = TEXT
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -30, 0, 2)
close.BackgroundTransparency = 1
close.Text = "X"
close.Font = Enum.Font.Code
close.TextSize = 14
close.TextColor3 = SUBTEXT
close.Parent = titleBar

--==================================================
-- TAB BAR
--==================================================

local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(8, 36)
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.BackgroundColor3 = BG2
tabBar.BorderSizePixel = 1
tabBar.BorderColor3 = BORDER
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 2)
tabLayout.Parent = tabBar

local pages = {}
local tabs = {}

local function createPage()
    local page = Instance.new("ScrollingFrame")

    page.Position = UDim2.fromOffset(8, 78)
    page.Size = UDim2.new(1, -16, 1, -86)
    page.BackgroundColor3 = BG2
    page.BorderSizePixel = 1
    page.BorderColor3 = BORDER
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = ACCENT
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = main

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    table.insert(pages, page)

    return page
end

local ragePage = createPage()
local fovPage = createPage()
local worldPage = createPage()
local visualPage = createPage()
local settingsPage = createPage()

local function createTab(name, page)
    local button = Instance.new("TextButton")

    button.Size = UDim2.fromOffset(105, 30)
    button.BackgroundColor3 = BG
    button.BorderSizePixel = 1
    button.BorderColor3 = BORDER
    button.Text = name
    button.Font = Enum.Font.Code
    button.TextSize = 14
    button.TextColor3 = SUBTEXT
    button.AutoButtonColor = false
    button.Parent = tabBar

    tabs[name] = button

    button.MouseButton1Click:Connect(function()
        currentTab = name

        for _, p in ipairs(pages) do
            p.Visible = p == page
        end

        for tabName, tab in pairs(tabs) do
            if tabName == name then
                tab.BackgroundColor3 = PANEL2
                tab.TextColor3 = TEXT
                tab.BorderColor3 = ACCENT
            else
                tab.BackgroundColor3 = BG
                tab.TextColor3 = SUBTEXT
                tab.BorderColor3 = BORDER
            end
        end
    end)

    return button
end

createTab("RAGEBOT", ragePage)
createTab("FOV", fovPage)
createTab("WORLD", worldPage)
createTab("VISUALS", visualPage)
createTab("SETTINGS", settingsPage)

ragePage.Visible = true

tabs.RAGEBOT.BackgroundColor3 = PANEL2
tabs.RAGEBOT.TextColor3 = TEXT
tabs.RAGEBOT.BorderColor3 = ACCENT

--==================================================
-- UI HELPERS
--==================================================

local function section(page, text)
    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1, -4, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextColor3 = SUBTEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = page

    return label
end

local function toggle(page, text, default, callback)
    local row = Instance.new("Frame")

    row.Size = UDim2.new(1, -4, 0, 38)
    row.BackgroundColor3 = PANEL
    row.BorderSizePixel = 1
    row.BorderColor3 = BORDER
    row.Parent = page

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(10, 0)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextSize = 13
    label.TextColor3 = TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(48, 21)
    button.Position = UDim2.new(1, -58, 0.5, -10.5)
    button.BackgroundColor3 = default and ON_COLOR or OFF_COLOR
    button.BorderSizePixel = 0
    button.Text = default and "ON" or "OFF"
    button.Font = Enum.Font.Code
    button.TextSize = 10
    button.TextColor3 = TEXT
    button.AutoButtonColor = false
    button.Parent = row

    local state = default

    local function refresh()
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and ON_COLOR or OFF_COLOR
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)

    return {
        row = row,

        setState = function(value)
            state = value
            refresh()
            callback(state)
        end,

        getState = function()
            return state
        end
    }
end

local function slider(page, text, min, max, value, callback)
    local row = Instance.new("Frame")

    row.Size = UDim2.new(1, -4, 0, 55)
    row.BackgroundColor3 = PANEL
    row.BorderSizePixel = 1
    row.BorderColor3 = BORDER
    row.Parent = page

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(10, 4)
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextColor3 = TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text .. ": " .. tostring(value)
    label.Parent = row

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(10, 32)
    bar.Size = UDim2.new(1, -20, 0, 7)
    bar.BackgroundColor3 = Color3.fromRGB(57, 45, 90)
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = row

    local fillBar = Instance.new("Frame")
    fillBar.BackgroundColor3 = ACCENT
    fillBar.BorderSizePixel = 0
    fillBar.Size = UDim2.fromScale(
        math.clamp((value - min) / (max - min), 0, 1),
        1
    )
    fillBar.Parent = bar

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(13, 13)
    knob.Position = UDim2.fromScale(
        math.clamp((value - min) / (max - min), 0, 1),
        0.5
    )
    knob.BackgroundColor3 = TEXT
    knob.BorderSizePixel = 0
    knob.Parent = bar

    local dragging = false

    local function update(x)
        local percent = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0,
            1
        )

        local newValue = math.floor(
            min + (max - min) * percent + 0.5
        )

        fillBar.Size = UDim2.fromScale(percent, 1)
        knob.Position = UDim2.fromScale(percent, 0.5)
        label.Text = text .. ": " .. tostring(newValue)

        callback(newValue)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            update(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end)

    return row
end

--==================================================
-- RAGEBOT
--==================================================

section(ragePage, "MAIN")

local rageNearestRow = Instance.new("Frame")
rageNearestRow.Size = UDim2.new(1, -4, 0, 38)
rageNearestRow.BackgroundColor3 = PANEL
rageNearestRow.BorderSizePixel = 1
rageNearestRow.BorderColor3 = BORDER
rageNearestRow.Parent = ragePage

local function halfToggle(parent, x, text, default, callback)
    local label = Instance.new("TextLabel")

    label.BackgroundTransparency = 1
    label.Position = UDim2.new(x, 10, 0, 0)
    label.Size = UDim2.new(0.5, -75, 1, 0)
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextSize = 12
    label.TextColor3 = TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local button = Instance.new("TextButton")

    button.Size = UDim2.fromOffset(46, 21)
    button.Position = UDim2.new(x + 0.5, -56, 0.5, -10.5)
    button.BackgroundColor3 = default and ON_COLOR or OFF_COLOR
    button.Text = default and "ON" or "OFF"
    button.Font = Enum.Font.Code
    button.TextSize = 10
    button.TextColor3 = TEXT
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent

    local state = default

    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and ON_COLOR or OFF_COLOR
        callback(state)
    end)

    return {
        setState = function(v)
            state = v
            button.Text = v and "ON" or "OFF"
            button.BackgroundColor3 = v and ON_COLOR or OFF_COLOR
            callback(v)
        end,

        getState = function()
            return state
        end
    }
end

local rageToggle
local nearestToggle
local spinToggle
local flickbotToggle
local spoofersToggle
local tpLoopToggle
local unlockAllToggle

rageToggle = halfToggle(
    rageNearestRow,
    0,
    "Rage",
    false,
    function(state)
        rageEnabled = state

        if not state then
            nearestEnabled = false

            if nearestToggle then
                nearestToggle.setState(false)
            end
        end

        lockedY = nil
        lastPos = nil
    end
)

nearestToggle = halfToggle(
    rageNearestRow,
    0.5,
    "Nearest",
    false,
    function(state)
        nearestEnabled = rageEnabled and state
    end
)

toggle(
    ragePage,
    "Fast Melee",
    false,
    function(state)
        fastMeleeEnabled = state
        setFastMelee(state)
    end
)

spinToggle = toggle(
    ragePage,
    "Spin",
    false,
    function(state)
        spinEnabled = state
    end
)

slider(
    ragePage,
    "Spin Speed",
    5,
    500,
    5,
    function(value)
        spinSpeed = value
    end
)

section(ragePage, "FLICKBOT")

flickbotToggle = toggle(
    ragePage,
    "Flickbot",
    false,
    function(state)
        flickbotEnabled = state
        flickTimer = 0
    end
)

slider(
    ragePage,
    "Flick Angle",
    1,
    180,
    90,
    function(value)
        flickAngle = value
    end
)

slider(
    ragePage,
    "Flick Interval (ms)",
    1,
    500,
    80,
    function(value)
        flickInterval = value / 1000
    end
)

section(ragePage, "SPOOFERS")

spoofersToggle = toggle(
    ragePage,
    "Spoofers",
    false,
    function(state)
        spoofersEnabled = state
    end
)

section(ragePage, "TP LOOP")

tpLoopToggle = toggle(
    ragePage,
    "TP Far ↔ Return",
    false,
    function(state)
        tpLoopEnabled = state
        tpTimer = 0
        tpPhase = false
        tpReturnCFrame = nil
    end
)

slider(ragePage, "TP Distance", 10, 1000, 100, function(value)
    tpDistance = value
end)

slider(ragePage, "TP Interval (ms)", 1, 1000, 1, function(value)
    tpInterval = value / 1000
end)

slider(ragePage, "Up Offset", 0, 3, 0, function(value)
    tpUpOffset = value
end)

slider(ragePage, "Y Rotation", 0, 360, 90, function(value)
    tpYRotation = value
end)

section(ragePage, "Y-OFFSET")

toggle(ragePage, "Y-Offset", false, function(state)
    yOffsetEnabled = state
    lockedY = nil
end)

slider(ragePage, "Y-Offset", -3000, -7, -7, function(value)
    yOffset = value

    if yOffsetEnabled and not randomYOffsetEnabled then
        lockedY = nil
    end
end)

toggle(ragePage, "Random Y-Offset", false, function(state)
    randomYOffsetEnabled = state
    randomYOffsetTimer = 0

    if state then
        yOffset = math.random(-3000, -7)
        lockedY = nil
    end
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -4, 0, 40)
info.BackgroundTransparency = 1
info.Text = "Random Y-Offset changes every 0.1 seconds between -7 and -3000."
info.Font = Enum.Font.Code
info.TextSize = 11
info.TextColor3 = SUBTEXT
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = ragePage

--==================================================
-- FOV
--==================================================

section(fovPage, "FOV DISPLAY")

toggle(fovPage, "FOV Circle", false, function(state)
    fovEnabled = state
    fov.Visible = state
end)

toggle(fovPage, "Fill", true, function(state)
    fovFillEnabled = state
    updateFOV()
end)

toggle(fovPage, "Border", true, function(state)
    fovBorderEnabled = state
    updateFOV()
end)

toggle(fovPage, "Rotation", true, function(state)
    fovRotationEnabled = state
end)

local rainbowToggle

rainbowToggle = toggle(fovPage, "Rainbow", false, function(state)
    rainbowEnabled = state
end)

section(fovPage, "COLOR")

local presetFrame = Instance.new("Frame")
presetFrame.Size = UDim2.new(1, -4, 0, 44)
presetFrame.BackgroundColor3 = PANEL
presetFrame.BorderSizePixel = 1
presetFrame.BorderColor3 = BORDER
presetFrame.Parent = fovPage

local presetLayout = Instance.new("UIListLayout")
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
presetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
presetLayout.Padding = UDim.new(0, 7)
presetLayout.Parent = presetFrame

local presets = {
    {"RED", Color3.fromRGB(255, 60, 60)},
    {"BLUE", Color3.fromRGB(60, 140, 255)},
    {"PINK", Color3.fromRGB(255, 70, 180)},
    {"GREEN", Color3.fromRGB(70, 220, 100)},
    {"PURPLE", Color3.fromRGB(180, 80, 255)},
    {"WHITE", Color3.fromRGB(255, 255, 255)},
    {"ORANGE", Color3.fromRGB(255, 140, 40)},
    {"CYAN", Color3.fromRGB(40, 230, 255)}
}

for _, preset in ipairs(presets) do
    local button = Instance.new("TextButton")

    button.Size = UDim2.fromOffset(55, 28)
    button.BackgroundColor3 = preset[2]
    button.BorderSizePixel = 0
    button.Text = preset[1]
    button.Font = Enum.Font.Code
    button.TextSize = 8
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = presetFrame

    button.MouseButton1Click:Connect(function()
        ringColor = preset[2]

        local h, s, v = Color3.toHSV(ringColor)

        hue = math.floor(h * 360)
        saturation = math.floor(s * 100)
        brightness = math.floor(v * 100)

        rainbowEnabled = false
        rainbowToggle.setState(false)

        updateFOV()
    end)
end

section(fovPage, "CUSTOM COLOR")

slider(fovPage, "Hue", 0, 360, 210, function(value)
    hue = value
    ringColor = Color3.fromHSV(hue / 360, saturation / 100, brightness / 100)
    rainbowEnabled = false
    updateFOV()
end)

slider(fovPage, "Saturation", 0, 100, 100, function(value)
    saturation = value
    ringColor = Color3.fromHSV(hue / 360, saturation / 100, brightness / 100)
    rainbowEnabled = false
    updateFOV()
end)

slider(fovPage, "Brightness", 0, 100, 100, function(value)
    brightness = value
    ringColor = Color3.fromHSV(hue / 360, saturation / 100, brightness / 100)
    rainbowEnabled = false
    updateFOV()
end)

section(fovPage, "SIZE & MOVEMENT")

slider(fovPage, "FOV Size", 80, 600, fovSize, function(value)
    fovSize = value
    updateFOV()
end)

slider(fovPage, "Rotation Speed", 10, 300, rotationSpeed, function(value)
    rotationSpeed = value
end)

slider(fovPage, "Fill Transparency", 0, 95, math.floor(fillTransparency * 100), function(value)
    fillTransparency = value / 100
    updateFOV()
end)

slider(fovPage, "Border Thickness", 1, 10, borderThickness, function(value)
    borderThickness = value
    updateFOV()
end)

slider(fovPage, "Border Transparency", 0, 95, math.floor(borderTransparency * 100), function(value)
    borderTransparency = value / 100
    updateFOV()
end)

--==================================================
-- WORLD
--==================================================

section(worldPage, "WORLD")

toggle(worldPage, "Night Mode", false, function(state)
    nightMode = state
    Lighting.ClockTime = state and 0 or 14
end)

toggle(worldPage, "Galaxy Sky", false, function(state)
    galaxyMode = state

    local old = Lighting:FindFirstChild("GalaxySky")

    if old then
        old:Destroy()
    end

    if state then
        local sky = Instance.new("Sky")
        sky.Name = "GalaxySky"

        local id = "rbxassetid://159454299"

        sky.SkyboxBk = id
        sky.SkyboxDn = id
        sky.SkyboxFt = id
        sky.SkyboxLf = id
        sky.SkyboxRt = id
        sky.SkyboxUp = id

        sky.Parent = Lighting
    end
end)

toggle(worldPage, "Fullbright", false, function(state)
    fullbright = state

    if state then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

slider(worldPage, "Time of Day", 0, 24, 14, function(value)
    if not nightMode then
        Lighting.ClockTime = value
    end
end)

slider(worldPage, "Brightness", 0, 100, 50, function(value)
    Lighting.Brightness = value / 20
end)

--==================================================
-- VISUALS
--==================================================

section(visualPage, "VISUAL EFFECTS")

toggle(visualPage, "Blur", false, function(state)
    blurEnabled = state

    local blur = Lighting:FindFirstChild("MenuBlur")

    if state then
        if not blur then
            blur = Instance.new("BlurEffect")
            blur.Name = "MenuBlur"
            blur.Size = 8
            blur.Parent = Lighting
        end
    elseif blur then
        blur:Destroy()
    end
end)

toggle(visualPage, "Color Correction", false, function(state)
    colorCorrectionEnabled = state

    local cc = Lighting:FindFirstChild("MenuColorCorrection")

    if state then
        if not cc then
            cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "MenuColorCorrection"
            cc.Brightness = 0.05
            cc.Contrast = 0.1
            cc.Saturation = 0.15
            cc.Parent = Lighting
        end
    elseif cc then
        cc:Destroy()
    end
end)

--==================================================
-- UNLOCK ALL
--==================================================

section(visualPage, "COSMETICS")

unlockAllToggle = toggle(
    visualPage,
    "Unlock All",
    false,
    function(state)
        setUnlockAll(state)
    end
)

--==================================================
-- SETTINGS
--==================================================

section(settingsPage, "UI COLOR")

local menuButton

local function applyUIColor(color)
    ACCENT = color
    ACCENT2 = color:Lerp(Color3.new(1, 1, 1), 0.25)
    BORDER = color:Lerp(Color3.new(0, 0, 0), 0.45)

    mainStroke.Color = BORDER
    tabBar.BorderColor3 = BORDER

    for _, page in ipairs(pages) do
        page.BorderColor3 = BORDER
        page.ScrollBarImageColor3 = ACCENT
    end

    for name, tab in pairs(tabs) do
        if name == currentTab then
            tab.BackgroundColor3 = PANEL2
            tab.TextColor3 = TEXT
            tab.BorderColor3 = ACCENT
        else
            tab.BackgroundColor3 = BG
            tab.TextColor3 = SUBTEXT
            tab.BorderColor3 = BORDER
        end
    end

    if menuButton then
        menuButton.BorderColor3 = ACCENT
    end
end

local function updateUIColor()
    local color = Color3.fromHSV(uiHue / 360, uiSaturation / 100, uiBrightness / 100)
    applyUIColor(color)
end

section(settingsPage, "COLOR PRESETS")

local uiPresetFrame = Instance.new("Frame")
uiPresetFrame.Size = UDim2.new(1, -4, 0, 80)
uiPresetFrame.BackgroundColor3 = PANEL
uiPresetFrame.BorderSizePixel = 1
uiPresetFrame.BorderColor3 = BORDER
uiPresetFrame.Parent = settingsPage

local uiPresetLayout = Instance.new("UIGridLayout")
uiPresetLayout.CellSize = UDim2.fromOffset(100, 28)
uiPresetLayout.CellPadding = UDim2.fromOffset(7, 7)
uiPresetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiPresetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiPresetLayout.Parent = uiPresetFrame

local uiPresets = {
    {"PURPLE", Color3.fromRGB(170, 40, 125)},
    {"BLUE", Color3.fromRGB(45, 100, 220)},
    {"CYAN", Color3.fromRGB(30, 190, 220)},
    {"GREEN", Color3.fromRGB(40, 190, 90)},
    {"RED", Color3.fromRGB(220, 50, 60)},
    {"ORANGE", Color3.fromRGB(230, 110, 35)}
}

for _, preset in ipairs(uiPresets) do
    local button = Instance.new("TextButton")

    button.BackgroundColor3 = preset[2]
    button.BorderSizePixel = 0
    button.Text = preset[1]
    button.Font = Enum.Font.Code
    button.TextSize = 10
    button.TextColor3 = Color3.new(1, 1, 1)
    button.AutoButtonColor = false
    button.Parent = uiPresetFrame

    button.MouseButton1Click:Connect(function()
        local h, s, v = Color3.toHSV(preset[2])

        uiHue = math.floor(h * 360)
        uiSaturation = math.floor(s * 100)
        uiBrightness = math.floor(v * 100)

        applyUIColor(preset[2])
    end)
end

section(settingsPage, "CUSTOM UI COLOR")

slider(settingsPage, "UI Hue", 0, 360, uiHue, function(value)
    uiHue = value
    updateUIColor()
end)

slider(settingsPage, "UI Saturation", 0, 100, uiSaturation, function(value)
    uiSaturation = value
    updateUIColor()
end)

slider(settingsPage, "UI Brightness", 0, 100, uiBrightness, function(value)
    uiBrightness = value
    updateUIColor()
end)

--==================================================
-- MENU KEYBIND
--==================================================

section(settingsPage, "MENU KEYBIND")

local keybindRow = Instance.new("Frame")
keybindRow.Size = UDim2.new(1, -4, 0, 42)
keybindRow.BackgroundColor3 = PANEL
keybindRow.BorderSizePixel = 1
keybindRow.BorderColor3 = BORDER
keybindRow.Parent = settingsPage

local keybindLabel = Instance.new("TextLabel")
keybindLabel.BackgroundTransparency = 1
keybindLabel.Position = UDim2.fromOffset(10, 0)
keybindLabel.Size = UDim2.new(1, -160, 1, 0)
keybindLabel.Font = Enum.Font.Code
keybindLabel.TextSize = 13
keybindLabel.TextColor3 = TEXT
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Text = "Menu Keybind"
keybindLabel.Parent = keybindRow

local keybindButton = Instance.new("TextButton")
keybindButton.Size = UDim2.fromOffset(130, 26)
keybindButton.Position = UDim2.new(1, -140, 0.5, -13)
keybindButton.BackgroundColor3 = BG
keybindButton.BorderSizePixel = 1
keybindButton.BorderColor3 = ACCENT
keybindButton.TextColor3 = TEXT
keybindButton.Font = Enum.Font.Code
keybindButton.TextSize = 11
keybindButton.AutoButtonColor = false
keybindButton.Text = menuKeybind.Name
keybindButton.Parent = keybindRow

local function updateKeybindButton()
    if waitingForKeybind then
        keybindButton.Text = "PRESS KEY..."
        keybindButton.BackgroundColor3 = PANEL2
        keybindButton.BorderColor3 = ON_COLOR
    else
        keybindButton.Text = menuKeybind.Name
        keybindButton.BackgroundColor3 = BG
        keybindButton.BorderColor3 = ACCENT
    end
end

keybindButton.MouseButton1Click:Connect(function()
    waitingForKeybind = true
    updateKeybindButton()
end)

section(settingsPage, "CONFIG LIST")

local configFrame = Instance.new("Frame")
configFrame.Size = UDim2.new(1, -4, 0, 200)
configFrame.BackgroundColor3 = PANEL
configFrame.BorderSizePixel = 1
configFrame.BorderColor3 = BORDER
configFrame.Parent = settingsPage

local configLayout = Instance.new("UIListLayout")
configLayout.Padding = UDim.new(0, 6)
configLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
configLayout.VerticalAlignment = Enum.VerticalAlignment.Top
configLayout.Parent = configFrame

local configPadding = Instance.new("UIPadding")
configPadding.PaddingTop = UDim.new(0, 8)
configPadding.PaddingBottom = UDim.new(0, 8)
configPadding.PaddingLeft = UDim.new(0, 8)
configPadding.PaddingRight = UDim.new(0, 8)
configPadding.Parent = configFrame

local configButtons = {}

--==================================================
-- CONFIG SYSTEM
--==================================================

local function saveConfig(index)
    configs[index] = {
        rageEnabled = rageEnabled,
        nearestEnabled = nearestEnabled,
        fastMeleeEnabled = fastMeleeEnabled,
        spinEnabled = spinEnabled,
        spinSpeed = spinSpeed,
        flickbotEnabled = flickbotEnabled,
        flickAngle = flickAngle,
        flickInterval = flickInterval,
        spoofersEnabled = spoofersEnabled,
        tpLoopEnabled = tpLoopEnabled,
        tpDistance = tpDistance,
        tpInterval = tpInterval,
        tpUpOffset = tpUpOffset,
        tpYRotation = tpYRotation,
        yOffsetEnabled = yOffsetEnabled,
        yOffset = yOffset,
        randomYOffsetEnabled = randomYOffsetEnabled,
        fovEnabled = fovEnabled,
        fovFillEnabled = fovFillEnabled,
        fovBorderEnabled = fovBorderEnabled,
        fovRotationEnabled = fovRotationEnabled,
        rainbowEnabled = rainbowEnabled,
        fovSize = fovSize,
        rotationSpeed = rotationSpeed,
        fillTransparency = fillTransparency,
        borderTransparency = borderTransparency,
        borderThickness = borderThickness,
        ringColor = ringColor,
        nightMode = nightMode,
        galaxyMode = galaxyMode,
        fullbright = fullbright,
        blurEnabled = blurEnabled,
        colorCorrectionEnabled = colorCorrectionEnabled,
        unlockAllEnabled = unlockAllEnabled,
        uiHue = uiHue,
        uiSaturation = uiSaturation,
        uiBrightness = uiBrightness,

        -- KEYBIND
        menuKeybind = menuKeybind
    }
end

local function loadConfig(index)
    local config = configs[index]

    if not config then
        return false
    end

    rageEnabled = config.rageEnabled
    nearestEnabled = config.nearestEnabled
    fastMeleeEnabled = config.fastMeleeEnabled or false
    spinEnabled = config.spinEnabled or false
    spinSpeed = config.spinSpeed or 5
    flickbotEnabled = config.flickbotEnabled or false
    flickAngle = config.flickAngle or 90
    flickInterval = config.flickInterval or 0.08
    spoofersEnabled = config.spoofersEnabled or false
    tpLoopEnabled = config.tpLoopEnabled or false
    tpDistance = config.tpDistance or 100
    tpInterval = config.tpInterval or 0.001
    tpUpOffset = config.tpUpOffset or 0
    tpYRotation = config.tpYRotation or 90
    yOffsetEnabled = config.yOffsetEnabled
    yOffset = config.yOffset
    randomYOffsetEnabled = config.randomYOffsetEnabled
    fovEnabled = config.fovEnabled
    fovFillEnabled = config.fovFillEnabled
    fovBorderEnabled = config.fovBorderEnabled
    fovRotationEnabled = config.fovRotationEnabled
    rainbowEnabled = config.rainbowEnabled
    fovSize = config.fovSize
    rotationSpeed = config.rotationSpeed
    fillTransparency = config.fillTransparency
    borderTransparency = config.borderTransparency
    borderThickness = config.borderThickness
    ringColor = config.ringColor
    nightMode = config.nightMode
    galaxyMode = config.galaxyMode
    fullbright = config.fullbright
    blurEnabled = config.blurEnabled
    colorCorrectionEnabled = config.colorCorrectionEnabled
    unlockAllEnabled = config.unlockAllEnabled or false
    uiHue = config.uiHue
    uiSaturation = config.uiSaturation
    uiBrightness = config.uiBrightness

    -- KEYBIND
    if config.menuKeybind then
        menuKeybind = config.menuKeybind
    else
        menuKeybind = Enum.KeyCode.RightShift
    end

    updateKeybindButton()

    setFastMelee(fastMeleeEnabled)

    if spinToggle then
        spinToggle.setState(spinEnabled)
    end

    if flickbotToggle then
        flickbotToggle.setState(flickbotEnabled)
    end

    if spoofersToggle then
        spoofersToggle.setState(spoofersEnabled)
    end

    if tpLoopToggle then
        tpLoopToggle.setState(tpLoopEnabled)
    end

    if unlockAllToggle then
        unlockAllToggle.setState(unlockAllEnabled)
    end

    lockedY = nil
    lastPos = nil
    tpTimer = 0
    tpPhase = false
    tpReturnCFrame = nil

    fov.Visible = fovEnabled

    updateFOV()
    updateUIColor()

    return true
end

local function createConfigRow(index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = configFrame

    local select = Instance.new("TextButton")
    select.Size = UDim2.new(0.42, -4, 1, 0)
    select.Position = UDim2.fromOffset(0, 0)
    select.BackgroundColor3 = BG
    select.BorderSizePixel = 1
    select.BorderColor3 = BORDER
    select.Text = "Config " .. index
    select.Font = Enum.Font.Code
    select.TextSize = 11
    select.TextColor3 = TEXT
    select.AutoButtonColor = false
    select.Parent = row

    local save = Instance.new("TextButton")
    save.Size = UDim2.new(0.27, -4, 1, 0)
    save.Position = UDim2.new(0.43, 0, 0, 0)
    save.BackgroundColor3 = ACCENT2
    save.BorderSizePixel = 0
    save.Text = "SAVE"
    save.Font = Enum.Font.Code
    save.TextSize = 10
    save.TextColor3 = TEXT
    save.AutoButtonColor = false
    save.Parent = row

    local load = Instance.new("TextButton")
    load.Size = UDim2.new(0.27, -4, 1, 0)
    load.Position = UDim2.new(0.70, 0, 0, 0)
    load.BackgroundColor3 = ACCENT2
    load.BorderSizePixel = 0
    load.Text = "LOAD"
    load.Font = Enum.Font.Code
    load.TextSize = 10
    load.TextColor3 = TEXT
    load.AutoButtonColor = false
    load.Parent = row

    configButtons[index] = select

    select.MouseButton1Click:Connect(function()
        selectedConfig = index

        for i, button in pairs(configButtons) do
            if i == selectedConfig then
                button.BackgroundColor3 = PANEL2
                button.BorderColor3 = ACCENT
            else
                button.BackgroundColor3 = BG
                button.BorderColor3 = BORDER
            end
        end
    end)

    save.MouseButton1Click:Connect(function()
        saveConfig(index)
        selectedConfig = index
        select.Text = "Config " .. index .. " ✓"

        for i, button in pairs(configButtons) do
            if i == selectedConfig then
                button.BackgroundColor3 = PANEL2
                button.BorderColor3 = ACCENT
            else
                button.BackgroundColor3 = BG
                button.BorderColor3 = BORDER
            end
        end
    end)

    load.MouseButton1Click:Connect(function()
        if loadConfig(index) then
            selectedConfig = index
            select.Text = "Config " .. index .. " ✓"

            for i, button in pairs(configButtons) do
                if i == selectedConfig then
                    button.BackgroundColor3 = PANEL2
                    button.BorderColor3 = ACCENT
                else
                    button.BackgroundColor3 = BG
                    button.BorderColor3 = BORDER
                end
            end
        end
    end)
end

for i = 1, 5 do
    createConfigRow(i)
end

configButtons[1].BackgroundColor3 = PANEL2
configButtons[1].BorderColor3 = ACCENT

--==================================================
-- RAGEBOT MOVEMENT
--==================================================

local function getNearestPlayer()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return nil
    end

    local nearest = nil
    local distance = math.huge

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local otherCharacter = other.Character
            local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
            local humanoid = otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")

            if otherRoot and humanoid and humanoid.Health > 0 then
                local d = (root.Position - otherRoot.Position).Magnitude

                if d < distance then
                    distance = d
                    nearest = other
                end
            end
        end
    end

    return nearest
end

local function dashToNearest()
    if not rageEnabled or not nearestEnabled then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local target = getNearestPlayer()

    if not target then
        return
    end

    local targetCharacter = target.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

    if targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, -7, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

--==================================================
-- HEARTBEAT
--==================================================

RunService.Heartbeat:Connect(function(dt)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        lockedY = nil
        lastPos = nil
        randomYOffsetTimer = 0
        tpTimer = 0
        tpPhase = false
        tpReturnCFrame = nil
        return
    end

    local spinAmount = math.rad(spinSpeed * 20) * dt

    if spinEnabled then
        root.CFrame = root.CFrame * CFrame.Angles(0, spinAmount, 0)
    end

    if flickbotEnabled then
        flickTimer += dt

        if flickTimer >= flickInterval then
            flickTimer = 0

            root.CFrame =
                root.CFrame
                * CFrame.Angles(0, math.rad(flickAngle), 0)
        end
    end

    if tpLoopEnabled then
        tpTimer += dt

        if tpTimer >= tpInterval then
            tpTimer = 0

            if not tpPhase then
                tpReturnCFrame = root.CFrame

                root.CFrame =
                    root.CFrame
                    * CFrame.new(0, tpUpOffset, -tpDistance)
                    * CFrame.Angles(0, math.rad(tpYRotation), 0)

                tpPhase = true
            elseif tpReturnCFrame then
                root.CFrame = tpReturnCFrame
                tpPhase = false
            end

            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if spoofersEnabled then
        -- Local test-state hook.
    end

    if not rageEnabled then
        return
    end

    if randomYOffsetEnabled then
        randomYOffsetTimer += dt

        if randomYOffsetTimer >= randomYOffsetInterval then
            randomYOffsetTimer = 0
            yOffset = math.random(-3000, -7)
            lockedY = nil
        end
    end

    local currentPos = root.Position

    if not lockedY then
        local offset

        if randomYOffsetEnabled then
            offset = yOffset
        elseif yOffsetEnabled then
            offset = yOffset
        else
            offset = -7
        end

        lockedY = currentPos.Y + offset
    end

    local moveDir = humanoid.MoveDirection

    if moveDir.Magnitude > 0 then
        lastPos =
            root.Position
            + moveDir * humanoid.WalkSpeed * 0.016
    elseif not lastPos then
        lastPos = currentPos
    end

    local finalCFrame =
        CFrame.new(lastPos.X, lockedY, lastPos.Z)
        * (root.CFrame - currentPos)

    if spinEnabled then
        finalCFrame =
            finalCFrame
            * CFrame.Angles(0, spinAmount, 0)
    end

    root.CFrame = finalCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    dashToNearest()
end)

--==================================================
-- FOV RENDER
--==================================================

RunService.RenderStepped:Connect(function(dt)

    if fov.Visible and fovRotationEnabled then
        fovGradient.Rotation =
            (fovGradient.Rotation + dt * rotationSpeed) % 360
    end

    if rainbowEnabled then
        ringColor =
            Color3.fromHSV(
                (os.clock() * 0.15) % 1,
                1,
                1
            )

        updateFOV()
    end
end)

--==================================================
-- WINDOW DRAG
--==================================================

local dragging = false
local dragStart
local startPosition

titleBar.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    main.Position =
        UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==================================================
-- OPEN / CLOSE
--==================================================

local function setMenuOpen(state)
    menuOpen = state
    main.Visible = state
end

close.MouseButton1Click:Connect(function()
    setMenuOpen(false)
end)

--==================================================
-- CUSTOM KEYBIND INPUT
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    -- When selecting a new keybind
    if waitingForKeybind then

        if input.KeyCode == Enum.KeyCode.Unknown then
            return
        end

        menuKeybind = input.KeyCode
        waitingForKeybind = false

        updateKeybindButton()

        return
    end

    -- Toggle menu with selected key
    if input.KeyCode == menuKeybind then
        setMenuOpen(not menuOpen)
    end
end)

--==================================================
-- FLOATING BUTTON
--==================================================

menuButton = Instance.new("TextButton")
menuButton.Name = "MenuToggle"
menuButton.Size = UDim2.fromOffset(90, 30)
menuButton.Position = UDim2.fromOffset(22, 142)
menuButton.BackgroundColor3 = Color3.fromRGB(25, 18, 55)
menuButton.BorderSizePixel = 1
menuButton.BorderColor3 = ACCENT
menuButton.Text = "Toggle UI"
menuButton.Font = Enum.Font.Code
menuButton.TextSize = 10
menuButton.TextColor3 = Color3.fromRGB(240, 235, 255)
menuButton.AutoButtonColor = false
menuButton.Active = true
menuButton.ZIndex = 10
menuButton.Parent = gui

menuButton.MouseEnter:Connect(function()
    menuButton.BackgroundColor3 = Color3.fromRGB(34, 24, 70)
end)

menuButton.MouseLeave:Connect(function()
    menuButton.BackgroundColor3 = Color3.fromRGB(25, 18, 55)
end)

--==================================================
-- FLOATING BUTTON CLICK + DRAG
--==================================================

local buttonDragging = false
local buttonDragStart
local buttonStartPosition
local buttonMoved = false

menuButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        buttonDragging = true
        buttonMoved = false
        buttonDragStart = input.Position
        buttonStartPosition = menuButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not buttonDragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - buttonDragStart

    if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
        buttonMoved = true
    end

    menuButton.Position =
        UDim2.new(
            buttonStartPosition.X.Scale,
            buttonStartPosition.X.Offset + delta.X,
            buttonStartPosition.Y.Scale,
            buttonStartPosition.Y.Offset + delta.Y
        )
end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        if buttonDragging and not buttonMoved then
            setMenuOpen(not menuOpen)
        end

        buttonDragging = false
    end
end)

--==================================================
-- INITIAL
--==================================================

updateFOV()
updateKeybindButton()