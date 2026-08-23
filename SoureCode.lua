--[[@
    Vision UI Library
    Version 1.0.0

    A compact, configurable Roblox UI library for executor environments.
    The public API intentionally stays close to the original Tempus module:

        local Vision = loadstring(game:HttpGet(".../Vision.lua"))()
        local window = Vision.Window({ title = "VISION", keybind = Enum.KeyCode.Insert })
        local tab = window:Tab("Combat", { icon = "crosshair" })
        local group = tab:Group("Aim", { side = "left" })
        group.Toggle({ text = "Enabled", flag = "aim_enabled" })
        group.Slider({ text = "FOV", min = 1, max = 180, default = 90, step = 1 })

        Slider options:
        min, max, default, step, decimals, suffix, flag, callback

        Theme options:
        Window({ theme = "Blue" })
        window:SetTheme("Rose")
        window.ThemeManager.List()

    All controls return a small object with Row, Get, and Set where useful.

--]]

local Vision = {}
Vision.Flags = {}
Vision.Version = "1.0.0"

local function runtimeEnvironment()
    if type(getgenv) == "function" then
        local ok, environment = pcall(getgenv)
        if ok and type(environment) == "table" then
            return environment
        end
    end
    return _G
end

local Runtime = runtimeEnvironment()
local RUNTIME_KEY = "__VISION_ACTIVE_WINDOW_V1"

function Vision.Unload()
    local previous = Runtime[RUNTIME_KEY]
    if type(previous) == "table" and type(previous.Destroy) == "function" then
        pcall(previous.Destroy)
    end
    Runtime[RUNTIME_KEY] = nil
    for flag in pairs(Vision.Flags) do
        Vision.Flags[flag] = nil
    end
end

local function getService(name)
    local ok, service = pcall(function()
        return game:GetService(name)
    end)
    if not ok or not service then
        return nil
    end
    if type(cloneref) == "function" then
        local cloned, result = pcall(cloneref, service)
        if cloned and result then
            return result
        end
    end
    return service
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local HttpService = getService("HttpService")

local function getLocalPlayer()
    return Players and Players.LocalPlayer
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, hiddenGui = pcall(gethui)
        if ok and hiddenGui then
            return hiddenGui
        end
    end
    if type(get_hidden_gui) == "function" then
        local ok, hiddenGui = pcall(get_hidden_gui)
        if ok and hiddenGui then
            return hiddenGui
        end
    end
    if CoreGui then
        return CoreGui
    end
    local player = getLocalPlayer()
    if player then
        return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
    end
    return nil
end

local function destroyExistingVisionGuis()
    local parent = getGuiParent()
    if not parent then
        return
    end
    pcall(function()
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") and child.Name == "Vision" then
                child:Destroy()
            end
        end
    end)
end

local function protectGui(gui)
    pcall(function()
        if syn and type(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        elseif type(protectgui) == "function" then
            protectgui(gui)
        end
    end)
end

-- Named icons remain optional. The logo is cached locally after its first download.
local ICON_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
local DEFAULT_LOGO_URL = "https://raw.githubusercontent.com/Flameware1/Vision/main/Vision.png"
local iconMap

local function loadIconMap()
    if iconMap ~= nil then
        return iconMap
    end
    iconMap = false
    if type(loadstring) ~= "function" then
        return iconMap
    end
    pcall(function()
        local source = game:HttpGet(ICON_URL)
        local chunk = loadstring(source)
        if type(chunk) == "function" then
            local ok, result = pcall(chunk)
            if ok and type(result) == "table" then
                iconMap = result
            end
        end
    end)
    return iconMap
end

local function resolveIcon(icon)
    if icon == nil or icon == 0 or icon == "" then
        return nil
    end
    if type(icon) == "number" then
        return { Image = "rbxassetid://" .. tostring(icon) }
    end
    if type(icon) ~= "string" then
        return nil
    end
    if string.match(icon, "^%d+$") then
        return { Image = "rbxassetid://" .. tostring(icon) }
    end
    if string.sub(icon, 1, 13) == "rbxassetid://" or string.sub(icon, 1, 4) == "http" then
        return { Image = icon }
    end
    local map = loadIconMap()
    if type(map) == "table" then
        local sized = map["48px"] or map
        local entry = sized and sized[string.lower(icon)]
        if type(entry) == "table" and entry[1] ~= nil and type(entry[2]) == "table" and type(entry[3]) == "table" then
            return {
                Image = "rbxassetid://" .. tostring(entry[1]),
                ImageRectSize = Vector2.new(tonumber(entry[2][1]) or 0, tonumber(entry[2][2]) or 0),
                ImageRectOffset = Vector2.new(tonumber(entry[3][1]) or 0, tonumber(entry[3][2]) or 0),
            }
        end
    end
    return nil
end

local function applyIcon(image, spec)
    if not spec or not spec.Image then
        image.Image = ""
        image.Visible = false
        return false
    end
    image.Image = spec.Image
    if spec.ImageRectSize then
        image.ImageRectSize = spec.ImageRectSize
    end
    if spec.ImageRectOffset then
        image.ImageRectOffset = spec.ImageRectOffset
    end
    image.Visible = true
    return true
end

local Theme = {
    Accent = Color3.fromRGB(56, 150, 255),
    AccentBright = Color3.fromRGB(96, 178, 255),
    AccentDark = Color3.fromRGB(18, 63, 112),
    AccentDeep = Color3.fromRGB(10, 35, 66),
    WindowBg = Color3.fromRGB(10, 13, 17),
    ChromeBg = Color3.fromRGB(7, 10, 14),
    PanelBg = Color3.fromRGB(15, 20, 27),
    ControlBg = Color3.fromRGB(22, 29, 38),
    ControlHover = Color3.fromRGB(28, 39, 51),
    ControlBorder = Color3.fromRGB(46, 62, 80),
    Track = Color3.fromRGB(26, 34, 44),
    TextWhite = Color3.fromRGB(241, 246, 252),
    TextBright = Color3.fromRGB(211, 225, 239),
    TextMid = Color3.fromRGB(145, 163, 181),
    TextDim = Color3.fromRGB(87, 105, 124),
    Check = Color3.fromRGB(6, 16, 26),
    Current = "Blue",
}

local ThemePresets = {
    Dark = {
        Accent = Color3.fromRGB(190, 196, 204),
        AccentBright = Color3.fromRGB(232, 236, 242),
        AccentDark = Color3.fromRGB(68, 74, 82),
        AccentDeep = Color3.fromRGB(34, 38, 44),
        WindowBg = Color3.fromRGB(12, 13, 15),
        ChromeBg = Color3.fromRGB(7, 8, 10),
        PanelBg = Color3.fromRGB(19, 20, 23),
        ControlBg = Color3.fromRGB(28, 30, 34),
        ControlHover = Color3.fromRGB(38, 41, 46),
        ControlBorder = Color3.fromRGB(62, 66, 74),
        Track = Color3.fromRGB(34, 36, 40),
        TextWhite = Color3.fromRGB(245, 246, 248),
        TextBright = Color3.fromRGB(218, 221, 226),
        TextMid = Color3.fromRGB(154, 158, 166),
        TextDim = Color3.fromRGB(94, 98, 106),
        Check = Color3.fromRGB(14, 16, 19),
    },
    Blue = {
        Accent = Color3.fromRGB(56, 150, 255),
        AccentBright = Color3.fromRGB(96, 178, 255),
        AccentDark = Color3.fromRGB(18, 63, 112),
        AccentDeep = Color3.fromRGB(10, 35, 66),
        WindowBg = Color3.fromRGB(10, 13, 17),
        ChromeBg = Color3.fromRGB(7, 10, 14),
        PanelBg = Color3.fromRGB(15, 20, 27),
        ControlBg = Color3.fromRGB(22, 29, 38),
        ControlHover = Color3.fromRGB(28, 39, 51),
        ControlBorder = Color3.fromRGB(46, 62, 80),
        Track = Color3.fromRGB(26, 34, 44),
        TextWhite = Color3.fromRGB(241, 246, 252),
        TextBright = Color3.fromRGB(211, 225, 239),
        TextMid = Color3.fromRGB(145, 163, 181),
        TextDim = Color3.fromRGB(87, 105, 124),
        Check = Color3.fromRGB(6, 16, 26),
    },
    Rose = {
        Accent = Color3.fromRGB(235, 105, 145),
        AccentBright = Color3.fromRGB(255, 150, 180),
        AccentDark = Color3.fromRGB(116, 39, 64),
        AccentDeep = Color3.fromRGB(66, 22, 39),
        WindowBg = Color3.fromRGB(18, 11, 15),
        ChromeBg = Color3.fromRGB(12, 7, 10),
        PanelBg = Color3.fromRGB(29, 17, 23),
        ControlBg = Color3.fromRGB(42, 24, 32),
        ControlHover = Color3.fromRGB(56, 31, 42),
        ControlBorder = Color3.fromRGB(84, 45, 59),
        Track = Color3.fromRGB(48, 27, 36),
        TextWhite = Color3.fromRGB(255, 243, 247),
        TextBright = Color3.fromRGB(239, 211, 220),
        TextMid = Color3.fromRGB(177, 137, 150),
        TextDim = Color3.fromRGB(111, 79, 91),
        Check = Color3.fromRGB(31, 10, 18),
    },
    Amethyst = {
        Accent = Color3.fromRGB(168, 116, 255),
        AccentBright = Color3.fromRGB(202, 166, 255),
        AccentDark = Color3.fromRGB(76, 43, 132),
        AccentDeep = Color3.fromRGB(43, 24, 77),
        WindowBg = Color3.fromRGB(15, 11, 22),
        ChromeBg = Color3.fromRGB(10, 7, 15),
        PanelBg = Color3.fromRGB(24, 17, 35),
        ControlBg = Color3.fromRGB(35, 25, 50),
        ControlHover = Color3.fromRGB(48, 34, 68),
        ControlBorder = Color3.fromRGB(72, 53, 101),
        Track = Color3.fromRGB(40, 29, 57),
        TextWhite = Color3.fromRGB(247, 242, 255),
        TextBright = Color3.fromRGB(223, 211, 240),
        TextMid = Color3.fromRGB(166, 148, 190),
        TextDim = Color3.fromRGB(102, 84, 126),
        Check = Color3.fromRGB(20, 12, 35),
    },
}

local themeBindings = {}
local ThemeManager = {}

local function themeName(name)
    name = tostring(name or "Blue")
    for presetName in pairs(ThemePresets) do
        if string.lower(presetName) == string.lower(name) then
            return presetName
        end
    end
    return nil
end

function ThemeManager.Set(name)
    local presetName = themeName(name)
    local preset = presetName and ThemePresets[presetName]
    if not preset then
        return false
    end
    for key, value in pairs(preset) do
        Theme[key] = value
    end
    Theme.Current = presetName
    return true
end

function ThemeManager.Apply(name, root)
    local previous = {}
    for key, value in pairs(Theme) do
        if typeof(value) == "Color3" then
            previous[key] = value
        end
    end
    if not ThemeManager.Set(name) then
        return false
    end

    local function replaceColor(value)
        if typeof(value) ~= "Color3" then
            return nil
        end
        for role, oldColor in pairs(previous) do
            if value == oldColor then
                return Theme[role]
            end
        end
        return nil
    end

    local function replaceColorSequence(value)
        if typeof(value) ~= "ColorSequence" then
            return nil
        end
        local changed = false
        local keypoints = {}
        for _, keypoint in ipairs(value.Keypoints) do
            local replacement = replaceColor(keypoint.Value)
            if replacement then
                keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(keypoint.Time, replacement)
                changed = true
            else
                keypoints[#keypoints + 1] = keypoint
            end
        end
        return changed and ColorSequence.new(keypoints) or nil
    end

    local function updateInstance(instance)
        local properties = {
            "BackgroundColor3",
            "BorderColor3",
            "Color",
            "ImageColor3",
            "ScrollBarImageColor3",
            "TextColor3",
        }
        for _, property in ipairs(properties) do
            local ok, value = pcall(function() return instance[property] end)
            if ok then
                local replacement = replaceColor(value) or replaceColorSequence(value)
                if replacement then
                    pcall(function() instance[property] = replacement end)
                end
            end
        end
    end

    for index = #themeBindings, 1, -1 do
        local binding = themeBindings[index]
        if not binding.instance or not binding.instance.Parent then
            table.remove(themeBindings, index)
        elseif not root or binding.instance == root or binding.instance:IsDescendantOf(root) then
            binding.instance[binding.property] = Theme[binding.role]
        end
    end
    if root then
        updateInstance(root)
        for _, descendant in ipairs(root:GetDescendants()) do
            updateInstance(descendant)
        end
    end
    return true
end

function ThemeManager.Get()
    return Theme.Current
end

function ThemeManager.List()
    local names = {}
    for name in pairs(ThemePresets) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

Vision.Themes = ThemePresets
Vision.ThemeManager = {
    Set = function(name)
        local current = Runtime[RUNTIME_KEY]
        return ThemeManager.Apply(name, current and current.Gui)
    end,
    Apply = function(name)
        local current = Runtime[RUNTIME_KEY]
        return ThemeManager.Apply(name, current and current.Gui)
    end,
    Get = ThemeManager.Get,
    List = ThemeManager.List,
}
Vision.ThemeNames = ThemeManager.List()

local WIN_W = 660
local WIN_H = 620
local TOPBAR_H = 56
local FOOTER_H = 30
local MARGIN = 16
local COL_GAP = 14
local COL_W = math.floor((WIN_W - MARGIN * 2 - COL_GAP) / 2)
local TOPBAR_SEARCH_X = MARGIN + 54
local TOPBAR_SEARCH_W = 174
local TOPBAR_TABS_X = MARGIN + 246
local TOPBAR_TABS_W = WIN_W - TOPBAR_TABS_X - MARGIN
local HEAD_H = 28
local TEXT = 13

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function tween(object, properties, duration, style, direction)
    if not object or not TweenService then
        return nil
    end
    local ok, result = pcall(function()
        local info = TweenInfo.new(
            duration or 0.16,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        )
        local animation = TweenService:Create(object, info, properties)
        animation:Play()
        return animation
    end)
    return ok and result or nil
end

local function make(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        if key ~= "Parent" then
            instance[key] = value
            if typeof(value) == "Color3" then
                for role, themeColor in pairs(Theme) do
                    if typeof(themeColor) == "Color3" and value == themeColor then
                        themeBindings[#themeBindings + 1] = {
                            instance = instance,
                            property = key,
                            role = role,
                        }
                        break
                    end
                end
            end
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function corner(parent, radius)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius or 4),
        Parent = parent,
    })
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or Theme.ControlBorder,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function keyName(keyCode)
    if not keyCode then
        return "None"
    end
    local pretty = {
        LeftShift = "LShift", RightShift = "RShift",
        LeftControl = "LCtrl", RightControl = "RCtrl",
        LeftAlt = "LAlt", RightAlt = "RAlt",
        KeypadZero = "Num 0", KeypadOne = "Num 1", KeypadTwo = "Num 2",
        KeypadThree = "Num 3", KeypadFour = "Num 4", KeypadFive = "Num 5",
        KeypadSix = "Num 6", KeypadSeven = "Num 7", KeypadEight = "Num 8",
        KeypadNine = "Num 9",
    }
    return pretty[keyCode.Name] or keyCode.Name
end

local CONFIG_FOLDER = "Vision"
local LOGO_FILE = CONFIG_FOLDER .. "/logo.png"

-- Converts localized/config values to display text without assuming a language key.
local function textValue(value, fallback)
    if value == nil then
        return fallback or ""
    end
    if type(value) == "string" or type(value) == "number" then
        return tostring(value)
    end
    if type(value) ~= "table" then
        return fallback or ""
    end
    for _, key in ipairs({ "text", "Text", "label", "Label", "name", "Name", "value", "Value", "default" }) do
        if value[key] ~= nil then
            local result = textValue(value[key], nil)
            if result ~= "" then
                return result
            end
        end
    end
    if value[1] ~= nil then
        local result = textValue(value[1], nil)
        if result ~= "" then
            return result
        end
    end
    for _, item in pairs(value) do
        local result = textValue(item, nil)
        if result ~= "" then
            return result
        end
    end
    return fallback or ""
end

local function objectName(value, fallback)
    local result = string.gsub(textValue(value, fallback or "Item"), "[^%w_%-]", "_")
    return result == "" and (fallback or "Item") or result
end

local function canUseFiles()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function ensureFolder()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return
    end
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        if not isfolder(CONFIG_FOLDER .. "/configs") then
            makefolder(CONFIG_FOLDER .. "/configs")
        end
    end)
end

local function configName(value)
    value = textValue(value, "default")
    value = string.gsub(value, "[^%w_%-]", "_")
    return value == "" and "default" or value
end

local function loadLogoAsset(url)
    if type(url) ~= "string" or url == "" then
        return nil
    end
    if string.sub(url, 1, 13) == "rbxassetid://" then
        return url
    end
    if type(writefile) ~= "function" or type(isfile) ~= "function" then
        return nil
    end
    ensureFolder()
    local downloaded, imageData = pcall(function()
        return game:HttpGet(url)
    end)
    if downloaded and type(imageData) == "string" and #imageData > 0 then
        pcall(function()
            writefile(LOGO_FILE, imageData)
        end)
    end
    if not isfile(LOGO_FILE) then
        return nil
    end
    local loaders = {}
    if type(getcustomasset) == "function" then
        loaders[#loaders + 1] = getcustomasset
    end
    if type(getsynasset) == "function" then
        loaders[#loaders + 1] = getsynasset
    end
    for _, loader in ipairs(loaders) do
        local ok, asset = pcall(loader, LOGO_FILE)
        if ok and type(asset) == "string" and asset ~= "" then
            return asset
        end
    end
    return nil
end

function Vision.Window(options)
    options = options or {}
    Vision.Unload()
    destroyExistingVisionGuis()
    for flag in pairs(Vision.Flags) do
        Vision.Flags[flag] = nil
    end
    local self = {}
    local menuKey = options.keybind or Enum.KeyCode.Insert

    if options.theme then
        ThemeManager.Set(options.theme)
    end
    if options.accent and typeof(options.accent) == "Color3" then
        Theme.Accent = options.accent
    end

    local screen = make("ScreenGui", {
        Name = "Vision",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    protectGui(screen)
    screen.Parent = getGuiParent()
    self.Gui = screen

    local connections = {}
    local destroyed = false
    local function track(connection)
        connections[#connections + 1] = connection
        return connection
    end

    local keybindCancel
    local controlListening = false
    local setMenuVisible
    local attachElements
    local openHuePopup
    local popupCleanup
    local flagBinds = {}

    local function bindFlag(flag, setter, getter)
        if flag and flag ~= "" then
            flagBinds[flag] = { set = setter, get = getter }
        end
    end

    function self.Destroy()
        if destroyed then
            return
        end
        destroyed = true
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        connections = {}
        flagBinds = {}
        for index = #themeBindings, 1, -1 do
            local binding = themeBindings[index]
            if not binding.instance or binding.instance == screen or binding.instance:IsDescendantOf(screen) then
                table.remove(themeBindings, index)
            end
        end
        if popupCleanup then
            pcall(popupCleanup)
            popupCleanup = nil
        end
        if Runtime[RUNTIME_KEY] == self then
            Runtime[RUNTIME_KEY] = nil
        end
        if screen then
            screen:Destroy()
        end
    end

    local function getViewport()
        local camera = workspace.CurrentCamera
        if camera and camera.ViewportSize.X > 100 then
            return camera.ViewportSize
        end
        return Vector2.new(1280, 720)
    end

    local viewport = getViewport()
    local win = make("Frame", {
        Name = "Window",
        Position = UDim2.new(
            0,
            math.max(20, math.floor((viewport.X - WIN_W) / 2)),
            0,
            math.max(20, math.floor((viewport.Y - WIN_H) / 2))
        ),
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        BackgroundColor3 = Theme.WindowBg,
        BorderSizePixel = 0,
        Parent = screen,
    })
    corner(win, 7)
    stroke(win, Theme.ControlBorder, 0.25)

    local topbar = make("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, TOPBAR_H),
        BackgroundColor3 = Theme.ChromeBg,
        BorderSizePixel = 0,
        Parent = win,
    })
    corner(topbar, 7)
    make("Frame", {
        Name = "TopbarFill",
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = Theme.ChromeBg,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    -- Local fallback mark: the downloaded PNG is preferred when the executor supports custom assets.
    local logo = make("Frame", {
        Name = "VisionLogo",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, MARGIN + 1, 0.5, 0),
        Size = UDim2.new(0, 32, 0, 30),
        BackgroundTransparency = 1,
        Parent = topbar,
    })
    local logoLeft = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.32, 0, 0.5, 0),
        Size = UDim2.new(0, 5, 0, 25),
        Rotation = 48,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = logo,
    })
    corner(logoLeft, 3)
    local logoRight = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.68, 0, 0.5, 0),
        Size = UDim2.new(0, 5, 0, 25),
        Rotation = -48,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = logo,
    })
    corner(logoRight, 3)
    local logoPupil = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 7, 0, 7),
        BackgroundColor3 = Theme.TextWhite,
        BorderSizePixel = 0,
        Parent = logo,
    })
    corner(logoPupil, 5)
    stroke(logoPupil, Theme.AccentBright, 0, 1)
    local logoImage = make("ImageLabel", {
        Name = "LogoImage",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        ImageTransparency = 0,
        Visible = false,
        ZIndex = 4,
        Parent = logo,
    })
    local logoHitbox = make("TextButton", {
        Name = "LogoButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = logo,
    })
    local logoAsset = loadLogoAsset(textValue(options.logo, DEFAULT_LOGO_URL))
    if logoAsset then
        logoImage.Image = logoAsset
        logoImage.Visible = true
        logoLeft.Visible = false
        logoRight.Visible = false
        logoPupil.Visible = false
    end

    local launcher = make("ImageButton", {
        Name = "Launcher",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.new(0, 42, 0, 42),
        BackgroundColor3 = Theme.ChromeBg,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Image = logoAsset or "",
        ImageColor3 = Theme.TextWhite,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 20,
        Parent = screen,
    })
    corner(launcher, 10)
    local launcherStroke = stroke(launcher, Theme.ControlBorder, 0.15, 1)
    local launcherScale = make("UIScale", { Scale = 1, Parent = launcher })
    if not logoAsset then
        launcher.Image = ""
        make("TextLabel", {
            Name = "FallbackMark",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = FONT_BOLD,
            Text = "V",
            TextSize = 16,
            TextColor3 = Theme.TextWhite,
            ZIndex = 21,
            Parent = launcher,
        })
    end

    logoHitbox.MouseEnter:Connect(function()
        tween(logoImage, { ImageTransparency = logoAsset and 0.08 or 1 }, 0.12)
        tween(logoLeft, { BackgroundColor3 = Theme.AccentBright }, 0.12)
        tween(logoRight, { BackgroundColor3 = Theme.AccentBright }, 0.12)
        tween(logoPupil, { BackgroundColor3 = Theme.TextWhite }, 0.12)
    end)
    logoHitbox.MouseLeave:Connect(function()
        tween(logoImage, { ImageTransparency = 0 }, 0.16)
        tween(logoLeft, { BackgroundColor3 = Theme.Accent }, 0.16)
        tween(logoRight, { BackgroundColor3 = Theme.Accent }, 0.16)
    end)
    launcher.MouseEnter:Connect(function()
        tween(launcherScale, { Scale = 1.08 }, 0.14, Enum.EasingStyle.Quint)
        tween(launcherStroke, { Color = Theme.AccentBright, Transparency = 0 }, 0.14)
    end)
    launcher.MouseLeave:Connect(function()
        tween(launcherScale, { Scale = 1 }, 0.18, Enum.EasingStyle.Quint)
        tween(launcherStroke, { Color = Theme.ControlBorder, Transparency = 0.15 }, 0.18)
    end)
    logoHitbox.MouseButton1Click:Connect(function()
        setMenuVisible(false)
    end)
    launcher.MouseButton1Click:Connect(function()
        setMenuVisible(true)
    end)

    local searchFrame = make("Frame", {
        Name = "SearchFrame",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, TOPBAR_SEARCH_X, 0.5, 0),
        Size = UDim2.new(0, TOPBAR_SEARCH_W, 0, 32),
        BackgroundColor3 = Theme.ControlBg,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    corner(searchFrame, 6)
    local searchStroke = stroke(searchFrame, Theme.ControlBorder, 0.2)
    local searchIcon = make("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 9, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        ImageColor3 = Theme.TextDim,
        ScaleType = Enum.ScaleType.Fit,
        Parent = searchFrame,
    })
    applyIcon(searchIcon, resolveIcon("search"))

    local searchBox = make("TextBox", {
        Name = "SearchBox",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 30, 0.5, 0),
        Size = UDim2.new(1, -58, 0, 26),
        BackgroundTransparency = 1,
        Font = FONT,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.TextDim,
        TextSize = 12,
        TextColor3 = Theme.TextBright,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchFrame,
    })
    local searchClear = make("TextButton", {
        Name = "ClearSearch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "x",
        Font = FONT_BOLD,
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        AutoButtonColor = false,
        Visible = false,
        Parent = searchFrame,
    })
    searchBox.MouseEnter:Connect(function()
        tween(searchStroke, { Color = Theme.AccentBright, Transparency = 0.08 }, 0.12)
    end)
    searchBox.MouseLeave:Connect(function()
        if not searchBox:IsFocused() then
            tween(searchStroke, { Color = Theme.ControlBorder, Transparency = 0.2 }, 0.16)
        end
    end)
    searchBox.Focused:Connect(function()
        tween(searchStroke, { Color = Theme.Accent, Transparency = 0 }, 0.12)
        tween(searchIcon, { ImageColor3 = Theme.AccentBright }, 0.12)
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchStroke, { Color = Theme.ControlBorder, Transparency = 0.2 }, 0.16)
        tween(searchIcon, { ImageColor3 = Theme.TextDim }, 0.16)
    end)
    searchClear.MouseEnter:Connect(function()
        tween(searchClear, { TextColor3 = Theme.TextWhite }, 0.1)
    end)
    searchClear.MouseLeave:Connect(function()
        tween(searchClear, { TextColor3 = Theme.TextDim }, 0.14)
    end)
    searchClear.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        searchBox:CaptureFocus()
    end)

    local tabHolder = make("ScrollingFrame", {
        Name = "TabHolder",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, TOPBAR_TABS_X, 0.5, 0),
        Size = UDim2.new(0, TOPBAR_TABS_W, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0,
        ScrollingEnabled = true,
        ClipsDescendants = true,
        Parent = topbar,
    })
    local tabList = make("Frame", {
        Name = "TabList",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = tabHolder,
    })
    tabHolder.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local nextX = tabHolder.CanvasPosition.X - input.Position.Z * 42
            tabHolder.CanvasPosition = Vector2.new(math.max(0, nextX), 0)
        end
    end)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = tabList,
    })

    make("Frame", {
        Name = "TopbarDivider",
        Position = UDim2.new(0, MARGIN, 0, TOPBAR_H),
        Size = UDim2.new(1, -MARGIN * 2, 0, 1),
        BackgroundColor3 = Theme.ControlBorder,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = win,
    })

    local content = make("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 0, 0, TOPBAR_H),
        Size = UDim2.new(1, 0, 1, -TOPBAR_H - FOOTER_H),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = win,
    })

    local footer = make("Frame", {
        Name = "Footer",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, FOOTER_H),
        BackgroundTransparency = 1,
        Parent = win,
    })
    make("Frame", {
        Name = "FooterDivider",
        Position = UDim2.new(0, MARGIN, 0, 0),
        Size = UDim2.new(1, -MARGIN * 2, 0, 1),
        BackgroundColor3 = Theme.ControlBorder,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = footer,
    })
    make("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, MARGIN, 0.5, 0),
        Size = UDim2.new(0, 180, 1, 0),
        BackgroundTransparency = 1,
        Font = FONT_MED,
        Text = "Vision v1.0.0",
        TextSize = 12,
        TextColor3 = Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })

    local overlay = make("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 50,
        Parent = win,
    })
    local overlayBlock = make("TextButton", {
        Name = "Block",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 50,
        Parent = overlay,
    })
    local overlayContent
    local overlayClose

    local function closeOverlay()
        if overlayContent then
            overlayContent:Destroy()
            overlayContent = nil
        end
        overlay.Visible = false
        if overlayClose then
            local callback = overlayClose
            overlayClose = nil
            callback()
        end
    end

    local function openOverlay(build, onClose)
        closeOverlay()
        overlayClose = onClose
        overlayContent = make("Frame", {
            Name = "OverlayContent",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex = 51,
            Parent = overlay,
        })
        overlay.Visible = true
        build(overlayContent)
    end

    track(overlayBlock.MouseButton1Click:Connect(closeOverlay))

    local tooltip = make("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 10, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.ControlBg,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 60,
        Parent = win,
    })
    corner(tooltip, 4)
    stroke(tooltip, Theme.ControlBorder, 0.25)
    local tooltipLabel = make("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = FONT,
        Text = "",
        TextSize = 12,
        TextColor3 = Theme.TextBright,
        ZIndex = 60,
        Parent = tooltip,
    })
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tooltipLabel,
    })

    local function showTooltip(text, anchor)
        tooltipLabel.Text = text
        local anchorPosition = anchor.AbsolutePosition
        local windowPosition = win.AbsolutePosition
        tooltip.Position = UDim2.new(
            0,
            anchorPosition.X - windowPosition.X - 4,
            0,
            anchorPosition.Y - windowPosition.Y + 21
        )
        tooltip.Visible = true
    end

    local function hideTooltip()
        tooltip.Visible = false
    end

    do
        local dragging = false
        local startPosition
        local startMouse
        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startMouse = input.Position
                startPosition = win.Position
            end
        end)
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and win.Visible then
                local delta = input.Position - startMouse
                win.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end))
    end

    local fadeProperties = {
        Frame = { "BackgroundTransparency" },
        TextLabel = { "BackgroundTransparency", "TextTransparency" },
        TextBox = { "BackgroundTransparency", "TextTransparency" },
        TextButton = { "BackgroundTransparency", "TextTransparency" },
        ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
        ImageButton = { "BackgroundTransparency", "ImageTransparency" },
        ScrollingFrame = { "BackgroundTransparency", "ScrollBarImageTransparency" },
        UIStroke = { "Transparency" },
    }

    local function collectFade(root)
        local result = {}
        local function collect(instance)
            local properties = fadeProperties[instance.ClassName]
            if properties then
                for _, property in ipairs(properties) do
                    result[#result + 1] = {
                        instance = instance,
                        property = property,
                        value = instance[property],
                    }
                end
            end
        end
        collect(root)
        for _, descendant in ipairs(root:GetDescendants()) do
            collect(descendant)
        end
        return result
    end

    local tabs = {}
    local activeTab
    local searchIndex = {}
    local switchGeneration = 0

    local function restorePage(tab)
        if tab.ActiveTweens then
            for _, animation in ipairs(tab.ActiveTweens) do
                pcall(function()
                    animation:Cancel()
                end)
            end
        end
        tab.ActiveTweens = nil
        if tab.LastCache then
            for _, entry in ipairs(tab.LastCache) do
                if entry.instance and entry.instance.Parent then
                    entry.instance[entry.property] = entry.value
                end
            end
        end
        tab.LastCache = nil
    end

    local function setActiveTab(tab)
        if activeTab == tab then
            return
        end
        closeOverlay()
        switchGeneration = switchGeneration + 1
        local generation = switchGeneration
        local oldTab = activeTab
        local oldIndex, newIndex = 0, 0
        for index, item in ipairs(tabs) do
            if item == oldTab then oldIndex = index end
            if item == tab then newIndex = index end
        end
        local direction = oldIndex ~= 0 and newIndex < oldIndex and -1 or 1

        if oldTab then
            restorePage(oldTab)
            oldTab.Page.Visible = false
            tween(oldTab.Nav, { TextColor3 = Theme.TextDim }, 0.14)
        end

        activeTab = tab
        tween(tab.Nav, { TextColor3 = Theme.TextWhite }, 0.14)
        task.defer(function()
            if tab.Nav and tab.Nav.Parent then
                local target = tab.Nav.AbsolutePosition.X - tabHolder.AbsolutePosition.X - 32
                tabHolder.CanvasPosition = Vector2.new(math.max(0, target), 0)
            end
        end)

        restorePage(tab)
        local cache = collectFade(tab.Page)
        tab.LastCache = cache
        tab.ActiveTweens = {}
        for _, entry in ipairs(cache) do
            entry.instance[entry.property] = 1
        end
        tab.Page.Position = UDim2.new(0, direction * 26, 0, 0)
        tab.Page.Visible = true
        tab.ActiveTweens[#tab.ActiveTweens + 1] = tween(
            tab.Page,
            { Position = UDim2.new(0, 0, 0, 0) },
            0.3,
            Enum.EasingStyle.Quint
        )

        local byGroup = {}
        for _, entry in ipairs(cache) do
            local groupBox
            for _, group in ipairs(tab.Groups) do
                if entry.instance == group.Box or entry.instance:IsDescendantOf(group.Box) then
                    groupBox = group.Box
                    break
                end
            end
            local key = groupBox or tab.Page
            byGroup[key] = byGroup[key] or {}
            byGroup[key][#byGroup[key] + 1] = entry
        end
        for index, group in ipairs(tab.Groups) do
            local entries = byGroup[group.Box]
            if entries then
                task.delay(0.02 + index * 0.03, function()
                    if destroyed or switchGeneration ~= generation or not tab.ActiveTweens then
                        return
                    end
                    for _, entry in ipairs(entries) do
                        tab.ActiveTweens[#tab.ActiveTweens + 1] = tween(
                            entry.instance,
                            { [entry.property] = entry.value },
                            0.2,
                            Enum.EasingStyle.Quad
                        )
                    end
                end)
            end
        end
        local looseEntries = byGroup[tab.Page]
        if looseEntries then
            for _, entry in ipairs(looseEntries) do
                tab.ActiveTweens[#tab.ActiveTweens + 1] = tween(
                    entry.instance,
                    { [entry.property] = entry.value },
                    0.18,
                    Enum.EasingStyle.Quad
                )
            end
        end
        task.delay(0.02 + #tab.Groups * 0.03 + 0.24, function()
            if not destroyed and switchGeneration == generation then
                tab.ActiveTweens = nil
                tab.LastCache = nil
            end
        end)
    end

    function self.Tab(name, tabOptions)
        tabOptions = tabOptions or {}
        local tabName = textValue(name, "Tab")
        local tabId = objectName(tabName, "Tab")
        local tab = { Name = tabName }
        local nav = make("TextButton", {
            Name = "Nav_" .. tabId,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = #tabs + 1,
            Text = tabName,
            Font = FONT_MED,
            TextSize = TEXT,
            TextColor3 = Theme.TextDim,
            TextXAlignment = Enum.TextXAlignment.Center,
            AutoButtonColor = false,
            Parent = tabList,
        })
        make("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = nav,
        })

        local page = make("ScrollingFrame", {
            Name = "Page_" .. tabId,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.ControlBorder,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = content,
        })
        local left = make("Frame", {
            Name = "ColLeft",
            Position = UDim2.new(0, MARGIN, 0, 12),
            Size = UDim2.new(0, COL_W, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = page,
        })
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, COL_GAP),
            Parent = left,
        })
        local right = make("Frame", {
            Name = "ColRight",
            Position = UDim2.new(0, MARGIN + COL_W + COL_GAP, 0, 12),
            Size = UDim2.new(0, COL_W, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = page,
        })
        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, COL_GAP),
            Parent = right,
        })
        make("UIPadding", {
            PaddingBottom = UDim.new(0, 14),
            Parent = page,
        })

        tab.Page = page
        tab.Nav = nav
        tab.ColL = left
        tab.ColR = right
        tab.Groups = {}

        nav.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setActiveTab(tab)
            end
        end)
        nav.MouseEnter:Connect(function()
            if activeTab ~= tab then
                tween(nav, { TextColor3 = Theme.TextBright }, 0.12)
            end
        end)
        nav.MouseLeave:Connect(function()
            if activeTab ~= tab then
                tween(nav, { TextColor3 = Theme.TextDim }, 0.16)
            end
        end)

        function tab.Group(groupName, groupOptions)
            groupOptions = groupOptions or {}
            groupName = textValue(groupName, "Group")
            local groupId = objectName(groupName, "Group")
            local group = {}
            local side = groupOptions.side
            if side ~= "left" and side ~= "right" then
                local leftCount, rightCount = 0, 0
                for _, existing in ipairs(tab.Groups) do
                    if existing.Side == "left" then
                        leftCount = leftCount + 1
                    else
                        rightCount = rightCount + 1
                    end
                end
                side = leftCount <= rightCount and "left" or "right"
            end
            local parentColumn = side == "left" and left or right
            local box = make("Frame", {
                Name = "Group_" .. groupId,
                Size = UDim2.new(1, 0, 0, HEAD_H),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.PanelBg,
                BorderSizePixel = 0,
                Parent = parentColumn,
            })
            corner(box, 4)
            stroke(box, Theme.ControlBorder, 0.25)
                local header = make("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, HEAD_H),
                BackgroundColor3 = Theme.AccentDeep,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = box,
            })
            corner(header, 4)
            local headerTitle = make("TextLabel", {
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_BOLD,
                Text = groupName,
                TextSize = TEXT,
                TextColor3 = Theme.TextWhite,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3,
                Parent = header,
            })
            if groupOptions.info then
                local info = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -9, 0.5, 0),
                    Size = UDim2.new(0, 15, 0, 15),
                    BackgroundColor3 = Theme.TextWhite,
                    BorderSizePixel = 0,
                    Text = "i",
                    Font = FONT_BOLD,
                    TextSize = 11,
                    TextColor3 = Theme.Check,
                    AutoButtonColor = false,
                    ZIndex = 3,
                    Parent = header,
                })
                corner(info, 8)
                info.MouseEnter:Connect(function()
                    showTooltip(textValue(groupOptions.info, ""), info)
                end)
                info.MouseLeave:Connect(hideTooltip)
            end
            local body = make("Frame", {
                Name = "Body",
                Position = UDim2.new(0, 0, 0, HEAD_H),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = box,
            })
            make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = body,
            })
            make("UIPadding", {
                PaddingTop = UDim.new(0, 9),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = body,
            })

            group.Box = box
            group.Body = body
            group.Name = groupName
            group.Side = side
            local order = 0
            local function nextOrder()
                order = order + 1
                return order
            end
            local function registerSearch(text, row)
                searchIndex[#searchIndex + 1] = {
                    tab = tab,
                    group = group,
                    text = textValue(text, ""),
                    row = row,
                }
            end
            group._nextOrder = nextOrder
            group._registerSearch = registerSearch
            tab.Groups[#tab.Groups + 1] = group
            attachElements(group)
            return group
        end

        function tab.Select()
            setActiveTab(tab)
        end

            tabs[#tabs + 1] = tab
        if not activeTab then
            setActiveTab(tab)
        end
        return tab
    end

    attachElements = function(group)
        local body = group.Body
        local nextOrder = group._nextOrder
        local registerSearch = group._registerSearch

        local function baseRow(height)
            return make("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundTransparency = 1,
                LayoutOrder = nextOrder(),
                Parent = body,
            })
        end

        function group.Label(options)
            options = options or {}
            local row = baseRow(options.height or 22)
            make("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT,
                Text = textValue(options.text, ""),
                TextSize = TEXT,
                TextColor3 = Theme.TextMid,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = row,
            })
            return { Row = row }
        end

        function group.Paragraph(options)
            options = options or {}
            local heading = textValue(options.title or options.text, "")
            local contentText = textValue(options.content or options.description, "")
            local height = tonumber(options.height) or (heading ~= "" and contentText ~= "" and 52 or 30)
            local row = baseRow(height)
            if heading ~= "" then
                make("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Font = FONT_MED,
                    Text = heading,
                    TextSize = TEXT,
                    TextColor3 = Theme.TextBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })
            end
            if contentText ~= "" then
                make("TextLabel", {
                    Position = UDim2.new(0, 0, 0, heading ~= "" and 19 or 0),
                    Size = UDim2.new(1, 0, 0, heading ~= "" and height - 19 or height),
                    BackgroundTransparency = 1,
                    Font = FONT,
                    Text = contentText,
                    TextSize = 12,
                    TextColor3 = Theme.TextMid,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Parent = row,
                })
            end
            if heading ~= "" or contentText ~= "" then
                registerSearch(heading .. " " .. contentText, row)
            end
            return { Row = row }
        end

        function group.Section(options)
            options = options or {}
            local text = textValue(options.text or options.title, "Section")
            local row = baseRow(24)
            make("TextLabel", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_BOLD,
                Text = text,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(text, row)
            return { Row = row }
        end

        function group.Separator(options)
            options = options or {}
            local row = baseRow(12)
            make("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = options.color and typeof(options.color) == "Color3" and options.color or Theme.ControlBorder,
                BorderSizePixel = 0,
                Parent = row,
            })
            return { Row = row }
        end

        function group.Spacer(options)
            options = options or {}
            local row = baseRow(math.max(2, tonumber(options.height) or 8))
            return { Row = row }
        end

        function group.Badge(options)
            options = options or {}
            local text = textValue(options.text or options.value, "Badge")
            local row = baseRow(24)
            local badge = make("TextLabel", {
                Size = UDim2.new(0, 0, 0, 20),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = options.color and typeof(options.color) == "Color3" and options.color or Theme.AccentDeep,
                BorderSizePixel = 0,
                Font = FONT_MED,
                Text = text,
                TextSize = 11,
                TextColor3 = Theme.TextBright,
                Parent = row,
            })
            corner(badge, 5)
            make("UIPadding", {
                PaddingLeft = UDim.new(0, 9),
                PaddingRight = UDim.new(0, 9),
                Parent = badge,
            })
            registerSearch(text, row)
            return { Row = row }
        end

        function group.Toggle(options)
            options = options or {}
            local state = options.default == true
            local hue, saturation, value = 0, 1, 1
            local hasColor = typeof(options.color) == "Color3"
            if hasColor then
                hue, saturation, value = options.color:ToHSV()
            end
            local row = baseRow(22)
            local label = make("TextLabel", {
                Size = UDim2.new(1, -64, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = textValue(options.text, "Toggle"),
                TextSize = TEXT,
                TextColor3 = Theme.TextMid,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(textValue(options.text, "Toggle"), row)
            local checkBox = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(checkBox, 4)
            local checkStroke = stroke(checkBox, Theme.ControlBorder, 0)
            local check = make("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 11, 0, 11),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.Check,
                ImageTransparency = 1,
                ScaleType = Enum.ScaleType.Fit,
                Parent = checkBox,
            })
            applyIcon(check, resolveIcon("check"))
            local swatch
            if hasColor then
                swatch = make("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -22, 0.5, 0),
                    Size = UDim2.new(0, 25, 0, 14),
                    BackgroundColor3 = Color3.fromHSV(hue, saturation, value),
                    BorderSizePixel = 0,
                    Parent = row,
                })
                corner(swatch, 3)
                stroke(swatch, Theme.ControlBorder, 0.15)
            end
            local function currentColor()
                return Color3.fromHSV(hue, saturation, value)
            end
            local function paint()
                if state then
                    tween(checkBox, { BackgroundColor3 = Theme.Accent }, 0.14)
                    tween(checkStroke, { Color = Theme.Accent }, 0.14)
                    tween(check, { ImageTransparency = 0 }, 0.14)
                    tween(label, { TextColor3 = Theme.TextBright }, 0.14)
                else
                    tween(checkBox, { BackgroundColor3 = Theme.ControlBg }, 0.14)
                    tween(checkStroke, { Color = Theme.ControlBorder }, 0.14)
                    tween(check, { ImageTransparency = 1 }, 0.14)
                    tween(label, { TextColor3 = Theme.TextMid }, 0.14)
                end
            end
            local function push(silent)
                if options.flag then Vision.Flags[options.flag] = state end
                if hasColor and options.colorFlag then Vision.Flags[options.colorFlag] = currentColor() end
                if not silent and options.callback then
                    task.spawn(options.callback, state)
                end
            end
            local function set(stateValue, silent)
                local nextState = stateValue == true
                if nextState == state then
                    return
                end
                state = nextState
                paint()
                push(silent)
            end
            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if swatch then
                        local position, size = swatch.AbsolutePosition, swatch.AbsoluteSize
                        local x, y = input.Position.X, input.Position.Y
                        if x >= position.X and x <= position.X + size.X and y >= position.Y and y <= position.Y + size.Y then
                            return
                        end
                    end
                    set(not state)
                end
            end)
            row.MouseEnter:Connect(function()
                if not state then tween(label, { TextColor3 = Theme.TextBright }, 0.1) end
            end)
            row.MouseLeave:Connect(function()
                if not state then tween(label, { TextColor3 = Theme.TextMid }, 0.16) end
            end)
            if swatch then
                local swatchStroke = swatch:FindFirstChildOfClass("UIStroke")
                swatch.MouseEnter:Connect(function()
                    tween(swatch, { Size = UDim2.new(0, 28, 0, 16) }, 0.12, Enum.EasingStyle.Quint)
                    if swatchStroke then tween(swatchStroke, { Color = Theme.AccentBright, Transparency = 0 }, 0.12) end
                end)
                swatch.MouseLeave:Connect(function()
                    tween(swatch, { Size = UDim2.new(0, 25, 0, 14) }, 0.16, Enum.EasingStyle.Quint)
                    if swatchStroke then tween(swatchStroke, { Color = Theme.ControlBorder, Transparency = 0.15 }, 0.16) end
                end)
                swatch.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        openHuePopup(swatch, function() return hue end, function(nextHue)
                            hue, saturation, value = nextHue, 1, 1
                            swatch.BackgroundColor3 = currentColor()
                            if options.colorFlag then Vision.Flags[options.colorFlag] = currentColor() end
                            if options.colorCallback then task.spawn(options.colorCallback, currentColor()) end
                        end)
                    end
                end)
            end
            paint()
            push(true)
            bindFlag(options.flag, function(v) set(v, false) end, function() return state end)
            if hasColor and options.colorFlag then
                bindFlag(options.colorFlag, function(v)
                    if typeof(v) == "Color3" then
                        hue, saturation, value = v:ToHSV()
                        swatch.BackgroundColor3 = currentColor()
                    end
                end, currentColor)
            end
            return {
                Row = row,
                Set = set,
                Get = function() return state end,
                SetColor = hasColor and function(color)
                    if typeof(color) == "Color3" then
                        hue, saturation, value = color:ToHSV()
                        swatch.BackgroundColor3 = currentColor()
                    end
                end or nil,
                GetColor = hasColor and currentColor or nil,
            }
        end

        function group.Keybind(options)
            options = options or {}
            local key = options.default
            local mode = options.mode or "Toggle"
            local listening = false
            local held = false
            local row = baseRow(22)
            local label = make("TextLabel", {
                Size = UDim2.new(1, -80, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT,
                Text = textValue(options.text, "Keybind"),
                TextSize = TEXT,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(textValue(options.text, "Keybind"), row)
            local keyLabel = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 120, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = "[ " .. keyName(key) .. " ]",
                TextSize = TEXT,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            local modeLabel = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -124, 0, 0),
                Size = UDim2.new(0, 55, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT,
                Text = textValue(mode, "Toggle"),
                TextSize = 10,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            local function stopListening()
                listening = false
                keyLabel.Text = "[ " .. keyName(key) .. " ]"
                tween(keyLabel, { TextColor3 = Theme.TextDim }, 0.1)
            end
            local function setKey(nextKey)
                key = nextKey
                keyLabel.Text = "[ " .. keyName(key) .. " ]"
                if options.flag then Vision.Flags[options.flag] = key and key.Name or "None" end
            end
            row.MouseEnter:Connect(function()
                tween(label, { TextColor3 = Theme.TextBright }, 0.12)
                tween(keyLabel, { TextColor3 = Theme.AccentBright }, 0.12)
            end)
            row.MouseLeave:Connect(function()
                if not listening then
                    tween(label, { TextColor3 = Theme.TextDim }, 0.16)
                    tween(keyLabel, { TextColor3 = Theme.TextDim }, 0.16)
                end
            end)
            row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if keybindCancel then keybindCancel() end
                    keybindCancel = stopListening
                    controlListening = true
                    listening = true
                    keyLabel.Text = "[ ... ]"
                    tween(keyLabel, { TextColor3 = Theme.AccentBright }, 0.1)
                end
            end)
            local active = false
            local function fire(isDown)
                if mode == "Hold" then
                    active = isDown
                    if options.callback then task.spawn(options.callback, active, key) end
                elseif mode == "Toggle" and isDown then
                    active = not active
                    if options.callback then task.spawn(options.callback, active, key) end
                elseif mode ~= "Toggle" and isDown then
                    if options.callback then task.spawn(options.callback, true, key) end
                end
            end
            track(UserInputService.InputBegan:Connect(function(input, processed)
                if listening and not processed and input.UserInputType == Enum.UserInputType.Keyboard then
                    setKey(input.KeyCode == Enum.KeyCode.Escape and nil or input.KeyCode)
                    keybindCancel = nil
                    stopListening()
                    task.defer(function() controlListening = false end)
                    if options.changed then task.spawn(options.changed, key) end
                    return
                end
                if processed or listening or controlListening then return end
                if key and input.KeyCode == key then
                    if mode == "Hold" then held = true end
                    fire(true)
                end
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if mode == "Hold" and key and input.KeyCode == key and held then
                    held = false
                    fire(false)
                end
            end))
            setKey(key)
            bindFlag(options.flag, function(v)
                if type(v) == "string" and v ~= "None" then
                    local ok, keyCode = pcall(function() return Enum.KeyCode[v] end)
                    setKey(ok and keyCode or nil)
                else
                    setKey(nil)
                end
            end, function() return key and key.Name or "None" end)
            return {
                Row = row,
                Set = setKey,
                Get = function() return key end,
                GetMode = function() return mode end,
                SetMode = function(nextMode)
                    if nextMode == "Toggle" or nextMode == "Hold" or nextMode == "Always" then
                        mode = nextMode
                        modeLabel.Text = mode
                    end
                end,
            }
        end

        function group.Slider(options)
            options = options or {}
            -- Explicit values make slider customization predictable and self-documenting.
            local min = tonumber(options.min)
            local max = tonumber(options.max)
            local step = tonumber(options.step or options.interval)
            min = min or 0
            max = max or 100
            if max < min then min, max = max, min end
            step = step or 1
            if step <= 0 then step = 1 end
            local decimals = options.decimals
            if decimals == nil then decimals = step % 1 ~= 0 and 2 or 0 end
            decimals = math.max(0, math.floor(tonumber(decimals) or 0))
            local value = math.clamp(tonumber(options.default or options.value) or min, min, max)
            value = min + math.floor((value - min) / step + 0.5) * step
            value = math.clamp(value, min, max)
            local row = baseRow(36)
            local label = make("TextLabel", {
                Size = UDim2.new(1, -90, 0, 18),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = textValue(options.text, "Slider"),
                TextSize = TEXT,
                TextColor3 = Theme.TextBright,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(textValue(options.text, "Slider"), row)
            local valueLabel = make("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 86, 0, 18),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                TextSize = TEXT,
                TextColor3 = Theme.TextBright,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            local rail = make("Frame", {
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 10),
                BackgroundColor3 = Theme.Track,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(rail, 4)
            stroke(rail, Theme.ControlBorder, 0.35)
            local fill = make("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = rail,
            })
            corner(fill, 4)
            local knob = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = Theme.TextWhite,
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = rail,
            })
            corner(knob, 6)
            stroke(knob, Theme.Accent, 0, 1)
            local sliderHitbox = make("TextButton", {
                Name = "SliderHitbox",
                Position = UDim2.new(0, -6, 0, -8),
                Size = UDim2.new(1, 12, 1, 16),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                Selectable = true,
                ZIndex = 4,
                Parent = rail,
            })
            local function format(valueToFormat)
                local result
                if decimals > 0 then
                    result = string.format("%." .. decimals .. "f", valueToFormat)
                else
                    result = tostring(math.floor(valueToFormat + 0.5))
                end
                return result .. textValue(options.suffix, "")
            end
            local function paint()
                local alpha = max > min and (value - min) / (max - min) or 0
                valueLabel.Text = format(value)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            end
            local function set(nextValue, silent)
                nextValue = tonumber(nextValue)
                if not nextValue then return end
                nextValue = math.clamp(nextValue, min, max)
                nextValue = min + math.floor((nextValue - min) / step + 0.5) * step
                nextValue = math.clamp(nextValue, min, max)
                if nextValue == value then
                    paint()
                    return
                end
                value = nextValue
                paint()
                if options.flag then Vision.Flags[options.flag] = value end
                if not silent and options.callback then task.spawn(options.callback, value) end
            end
            local dragging = false
            local function setFromX(x)
                local alpha = math.clamp(
                    (x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1),
                    0,
                    1
                )
                set(min + alpha * (max - min))
            end
            sliderHitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(input.Position.X)
                    tween(fill, { BackgroundColor3 = Theme.AccentBright }, 0.1)
                    tween(knob, { Size = UDim2.new(0, 14, 0, 14) }, 0.1, Enum.EasingStyle.Quint)
                end
            end)
            sliderHitbox.MouseEnter:Connect(function()
                tween(fill, { BackgroundColor3 = Theme.AccentBright }, 0.12)
                tween(knob, { Size = UDim2.new(0, 14, 0, 14) }, 0.12, Enum.EasingStyle.Quint)
            end)
            sliderHitbox.MouseLeave:Connect(function()
                if not dragging then
                    tween(fill, { BackgroundColor3 = Theme.Accent }, 0.16)
                    tween(knob, { Size = UDim2.new(0, 12, 0, 12) }, 0.16, Enum.EasingStyle.Quint)
                end
            end)
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    tween(fill, { BackgroundColor3 = Theme.Accent }, 0.14)
                    tween(knob, { Size = UDim2.new(0, 12, 0, 12) }, 0.14, Enum.EasingStyle.Quint)
                end
            end))
            track(UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end))
            sliderHitbox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Down then
                        set(value - step)
                    elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.Up then
                        set(value + step)
                    elseif input.KeyCode == Enum.KeyCode.Home then
                        set(min)
                    elseif input.KeyCode == Enum.KeyCode.End then
                        set(max)
                    end
                end
            end)
            paint()
            if options.flag then Vision.Flags[options.flag] = value end
            bindFlag(options.flag, function(v) set(v, false) end, function() return value end)
            return {
                Row = row,
                Set = set,
                Get = function() return value end,
                GetMin = function() return min end,
                GetMax = function() return max end,
                GetStep = function() return step end,
            }
        end

        function group.Dropdown(options)
            options = options or {}
            local values = options.options or {}
            local multi = options.multi == true
            local selected = multi and nil or options.default or values[1]
            local selectedSet = {}
            if multi then
                for _, item in ipairs(options.default or {}) do selectedSet[item] = true end
            end
            local row = baseRow(26)
            local label = make("TextLabel", {
                Size = UDim2.new(1, -130, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = textValue(options.text, "Dropdown"),
                TextSize = TEXT,
                TextColor3 = Theme.TextBright,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(textValue(options.text, "Dropdown"), row)
            local valueButton = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -24, 0.5, 0),
                Size = UDim2.new(0, 86, 0, 22),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(valueButton, 4)
            stroke(valueButton, Theme.ControlBorder, 0.3)
            local valueLabel = make("TextLabel", {
                Position = UDim2.new(0, 6, 0, 0),
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextBright,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = valueButton,
            })
            local chevronButton = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 22, 0, 22),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(chevronButton, 4)
            local chevron = make("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 11, 0, 11),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.TextMid,
                ScaleType = Enum.ScaleType.Fit,
                Parent = chevronButton,
            })
            applyIcon(chevron, resolveIcon("chevron-down"))
            local function current()
                if not multi then return selected end
                local result = {}
                for _, item in ipairs(values) do
                    if selectedSet[item] then result[#result + 1] = item end
                end
                return result
            end
            local function paint()
                if multi then
                    local result = current()
                    local display = {}
                    for _, item in ipairs(result) do
                        display[#display + 1] = textValue(item, "")
                    end
                    valueLabel.Text = #display > 0 and table.concat(display, ", ") or "None"
                else
                    valueLabel.Text = textValue(selected, "None")
                end
            end
            local function push(silent)
                if options.flag then Vision.Flags[options.flag] = current() end
                if not silent and options.callback then task.spawn(options.callback, current()) end
            end
            local isOpen = false
            local function openList()
                isOpen = true
                tween(chevron, { Rotation = 180 }, 0.15)
                openOverlay(function(root)
                    local windowPosition = win.AbsolutePosition
                    local buttonPosition = valueButton.AbsolutePosition
                    local width = 142
                    local height = math.min(#values, 8) * 25 + 8
                    local x = buttonPosition.X - windowPosition.X + valueButton.AbsoluteSize.X - width + 24
                    local y = buttonPosition.Y - windowPosition.Y + valueButton.AbsoluteSize.Y + 4
                    if y + height > WIN_H - FOOTER_H then
                        y = buttonPosition.Y - windowPosition.Y - height - 4
                    end
                    local list = make("ScrollingFrame", {
                        Position = UDim2.new(0, math.clamp(x, 8, WIN_W - width - 8), 0, y),
                        Size = UDim2.new(0, width, 0, height),
                        BackgroundColor3 = Theme.ControlBg,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.ControlBorder,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        ZIndex = 52,
                        Parent = root,
                    })
                    corner(list, 4)
                    stroke(list, Theme.ControlBorder, 0.2)
                    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
                    make("UIPadding", {
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        Parent = list,
                    })
                    for index, option in ipairs(values) do
                        local item = make("TextButton", {
                            Size = UDim2.new(1, 0, 0, 25),
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            LayoutOrder = index,
                            ZIndex = 53,
                            Parent = list,
                        })
                        local selectedNow = multi and selectedSet[option] or option == selected
                        local itemLabel = make("TextLabel", {
                            Position = UDim2.new(0, 10, 0, 0),
                            Size = UDim2.new(1, -20, 1, 0),
                            BackgroundTransparency = 1,
                            Font = FONT,
                            Text = textValue(option, ""),
                            TextSize = 12,
                            TextColor3 = selectedNow and Theme.AccentBright or Theme.TextMid,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 53,
                            Parent = item,
                        })
                        item.MouseEnter:Connect(function()
                            if not (multi and selectedSet[option] or option == selected) then
                                tween(itemLabel, { TextColor3 = Theme.TextBright }, 0.1)
                            end
                        end)
                        item.MouseLeave:Connect(function()
                            if not (multi and selectedSet[option] or option == selected) then
                                tween(itemLabel, { TextColor3 = Theme.TextMid }, 0.1)
                            end
                        end)
                        item.MouseButton1Click:Connect(function()
                            if multi then
                                selectedSet[option] = not selectedSet[option] or nil
                                itemLabel.TextColor3 = selectedSet[option] and Theme.AccentBright or Theme.TextMid
                                paint()
                                push(false)
                            else
                                selected = option
                                paint()
                                push(false)
                                closeOverlay()
                            end
                        end)
                    end
                end, function()
                    isOpen = false
                    tween(chevron, { Rotation = 0 }, 0.15)
                end)
            end
            local function toggleList(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if isOpen then closeOverlay() else openList() end
            end
            valueButton.MouseEnter:Connect(function()
                tween(valueButton, { BackgroundColor3 = Theme.ControlHover }, 0.12)
                tween(chevronButton, { BackgroundColor3 = Theme.ControlHover }, 0.12)
                tween(label, { TextColor3 = Theme.TextWhite }, 0.12)
            end)
            valueButton.MouseLeave:Connect(function()
                tween(valueButton, { BackgroundColor3 = Theme.ControlBg }, 0.16)
                tween(chevronButton, { BackgroundColor3 = Theme.ControlBg }, 0.16)
                tween(label, { TextColor3 = Theme.TextBright }, 0.16)
            end)
            chevronButton.InputBegan:Connect(toggleList)
            valueButton.InputBegan:Connect(toggleList)
            paint()
            push(true)
            bindFlag(options.flag, function(v)
                if multi and type(v) == "table" then
                    selectedSet = {}
                    for _, item in ipairs(v) do selectedSet[item] = true end
                elseif not multi then
                    selected = v
                end
                paint()
                push(false)
            end, current)
            return {
                Row = row,
                Set = function(v)
                    if multi and type(v) == "table" then
                        selectedSet = {}
                        for _, item in ipairs(v) do selectedSet[item] = true end
                    elseif not multi then
                        selected = v
                    end
                    paint()
                    push(false)
                end,
                Get = current,
                Refresh = function(newValues)
                    if type(newValues) ~= "table" then return end
                    values = newValues
                    local changed = false
                    if multi then
                        local kept = {}
                        for _, item in ipairs(values) do
                            if selectedSet[item] then kept[item] = true end
                        end
                        for item in pairs(selectedSet) do
                            if not kept[item] then changed = true end
                        end
                        selectedSet = kept
                    else
                        local found = false
                        for _, item in ipairs(values) do
                            if item == selected then found = true break end
                        end
                        if not found then selected, changed = values[1], true end
                    end
                    paint()
                    if changed then push(false) end
                end,
            }
        end

        function group.Color(options)
            options = options or {}
            local hue, saturation, value = 0, 1, 1
            if typeof(options.default) == "Color3" then hue, saturation, value = options.default:ToHSV() end
            local row = baseRow(22)
            make("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = textValue(options.text, "Color"),
                TextSize = TEXT,
                TextColor3 = Theme.TextBright,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            registerSearch(textValue(options.text, "Color"), row)
            local swatch = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 25, 0, 14),
                BackgroundColor3 = Color3.fromHSV(hue, saturation, value),
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(swatch, 3)
            stroke(swatch, Theme.ControlBorder, 0.15)
            local function current() return Color3.fromHSV(hue, saturation, value) end
            local function push(silent)
                if options.flag then Vision.Flags[options.flag] = current() end
                if not silent and options.callback then task.spawn(options.callback, current()) end
            end
            local swatchStroke = swatch:FindFirstChildOfClass("UIStroke")
            swatch.MouseEnter:Connect(function()
                tween(swatch, { Size = UDim2.new(0, 28, 0, 16) }, 0.12, Enum.EasingStyle.Quint)
                if swatchStroke then tween(swatchStroke, { Color = Theme.AccentBright, Transparency = 0 }, 0.12) end
            end)
            swatch.MouseLeave:Connect(function()
                tween(swatch, { Size = UDim2.new(0, 25, 0, 14) }, 0.16, Enum.EasingStyle.Quint)
                if swatchStroke then tween(swatchStroke, { Color = Theme.ControlBorder, Transparency = 0.15 }, 0.16) end
            end)
            swatch.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    openHuePopup(swatch, function() return hue end, function(nextHue)
                        hue, saturation, value = nextHue, 1, 1
                        swatch.BackgroundColor3 = current()
                        push(false)
                    end)
                end
            end)
            push(true)
            bindFlag(options.flag, function(v)
                if typeof(v) == "Color3" then
                    hue, saturation, value = v:ToHSV()
                    swatch.BackgroundColor3 = current()
                    push(false)
                end
            end, current)
            return {
                Row = row,
                Set = function(color)
                    if typeof(color) == "Color3" then
                        hue, saturation, value = color:ToHSV()
                        swatch.BackgroundColor3 = current()
                        push(false)
                    end
                end,
                Get = current,
            }
        end

        function group.Button(options)
            options = options or {}
            local row = baseRow(29)
            local button = make("Frame", {
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 0, 0, 2),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(button, 4)
            local buttonStroke = stroke(button, Theme.ControlBorder, 0.25)
            local buttonScale = make("UIScale", { Scale = 1, Parent = button })
            local label = make("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT_MED,
                Text = textValue(options.text, "Button"),
                TextSize = 12,
                TextColor3 = Theme.TextBright,
                Parent = button,
            })
            registerSearch(textValue(options.text, "Button"), row)
            button.MouseEnter:Connect(function()
                tween(buttonScale, { Scale = 1.015 }, 0.14, Enum.EasingStyle.Quint)
                tween(button, { BackgroundColor3 = Theme.ControlHover }, 0.14, Enum.EasingStyle.Quint)
                tween(buttonStroke, { Color = Theme.AccentBright, Transparency = 0.05 }, 0.14)
            end)
            button.MouseLeave:Connect(function()
                tween(buttonScale, { Scale = 1 }, 0.18, Enum.EasingStyle.Quint)
                tween(button, { BackgroundColor3 = Theme.ControlBg }, 0.2, Enum.EasingStyle.Quint)
                tween(buttonStroke, { Color = Theme.ControlBorder, Transparency = 0.25 }, 0.2)
            end)
            button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    tween(label, { TextColor3 = Theme.AccentBright }, 0.06)
                    task.delay(0.12, function() tween(label, { TextColor3 = Theme.TextBright }, 0.2) end)
                    if options.callback then task.spawn(options.callback) end
                end
            end)
            return { Row = row }
        end

        function group.Textbox(options)
            options = options or {}
            local row = baseRow(27)
            local text = textValue(options.text, "")
            if text ~= "" then
                make("TextLabel", {
                    Size = UDim2.new(1, -130, 1, 0),
                    BackgroundTransparency = 1,
                    Font = FONT_MED,
                    Text = text,
                    TextSize = TEXT,
                    TextColor3 = Theme.TextBright,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })
                registerSearch(text, row)
            end
            local inputBox = make("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = text ~= "" and UDim2.new(0, 112, 0, 22) or UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(inputBox, 4)
            local inputStroke = stroke(inputBox, Theme.ControlBorder, 0.25)
            local input = make("TextBox", {
                Position = UDim2.new(0, 7, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                BackgroundTransparency = 1,
                Font = FONT,
                Text = textValue(options.default, ""),
                PlaceholderText = textValue(options.placeholder, ""),
                PlaceholderColor3 = Theme.TextDim,
                TextSize = 12,
                TextColor3 = Theme.TextBright,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = inputBox,
            })
            local function setText(text, silent)
                input.Text = textValue(text, "")
                if options.flag then Vision.Flags[options.flag] = input.Text end
                if not silent and options.callback then task.spawn(options.callback, input.Text, false) end
            end
            input.MouseEnter:Connect(function()
                tween(inputStroke, { Color = Theme.AccentBright, Transparency = 0.1 }, 0.12)
            end)
            input.MouseLeave:Connect(function()
                if not input:IsFocused() then
                    tween(inputStroke, { Color = Theme.ControlBorder, Transparency = 0.25 }, 0.16)
                end
            end)
            input.Focused:Connect(function()
                tween(inputStroke, { Color = Theme.Accent, Transparency = 0.05 }, 0.1)
            end)
            input.FocusLost:Connect(function(enter)
                tween(inputStroke, { Color = Theme.ControlBorder, Transparency = 0.25 }, 0.12)
                if options.flag then Vision.Flags[options.flag] = input.Text end
                if options.callback then task.spawn(options.callback, input.Text, enter) end
            end)
            if options.flag then Vision.Flags[options.flag] = input.Text end
            bindFlag(options.flag, function(v) setText(v, false) end, function() return input.Text end)
            return {
                Row = row,
                Set = function(text) setText(text) end,
                Get = function() return input.Text end,
            }
        end

        group.Input = group.Textbox
        group.Text = group.Label
        group.Switch = group.Toggle
        group.Select = group.Dropdown
        group.ColorPicker = group.Color
        group.Action = group.Button
    end

    openHuePopup = function(anchor, getHue, setHue)
        openOverlay(function(root)
            local windowPosition = win.AbsolutePosition
            local anchorPosition = anchor.AbsolutePosition
            local width, height = 176, 42
            local x = math.clamp(
                anchorPosition.X - windowPosition.X + anchor.AbsoluteSize.X - width,
                8,
                WIN_W - width - 8
            )
            local y = anchorPosition.Y - windowPosition.Y + anchor.AbsoluteSize.Y + 6
            if y + height > WIN_H - FOOTER_H then
                y = anchorPosition.Y - windowPosition.Y - height - 6
            end
            local popup = make("Frame", {
                Position = UDim2.new(0, x, 0, y),
                Size = UDim2.new(0, width, 0, height),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                ZIndex = 52,
                Parent = root,
            })
            corner(popup, 4)
            stroke(popup, Theme.ControlBorder, 0.2)
            local rail = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -20, 0, 11),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 53,
                Parent = popup,
            })
            corner(rail, 5)
            make("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
                Parent = rail,
            })
            local knob = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(getHue(), 0, 0.5, 0),
                Size = UDim2.new(0, 7, 0, 16),
                BackgroundColor3 = Theme.TextWhite,
                BorderSizePixel = 0,
                ZIndex = 54,
                Parent = rail,
            })
            corner(knob, 3)
            stroke(knob, Theme.Check, 0, 1)
            local dragging = false
            local function setFromX(xPosition)
                local alpha = math.clamp(
                    (xPosition - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1),
                    0,
                    1
                )
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                setHue(alpha)
            end
            popup.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)
            local moveConnection = UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(input.Position.X)
                end
            end)
            local upConnection = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            popupCleanup = function()
                pcall(function() moveConnection:Disconnect() end)
                pcall(function() upConnection:Disconnect() end)
            end
        end, function()
            if popupCleanup then
                popupCleanup()
                popupCleanup = nil
            end
        end)
    end

    local searchToken = 0
    local function flashRow(row)
        local highlight = make("Frame", {
            Size = UDim2.new(1, 8, 1, 4),
            Position = UDim2.new(0, -4, 0, -2),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = row,
        })
        corner(highlight, 4)
        task.spawn(function()
            for _ = 1, 2 do
                tween(highlight, { BackgroundTransparency = 0.76 }, 0.16)
                task.wait(0.2)
                tween(highlight, { BackgroundTransparency = 1 }, 0.22)
                task.wait(0.26)
            end
            if highlight.Parent then highlight:Destroy() end
        end)
    end

    local function runSearch(query)
        query = string.lower(query or "")
        if query == "" then
            closeOverlay()
            return
        end
        searchToken = searchToken + 1
        local token = searchToken
        local hits = {}
        for _, entry in ipairs(searchIndex) do
            if string.find(string.lower(entry.text), query, 1, true)
                or string.find(string.lower(entry.group.Name), query, 1, true) then
                hits[#hits + 1] = entry
                if #hits >= 8 then break end
            end
        end
        openOverlay(function(root)
            local height = math.max(#hits, 1) * 27 + 8
            local list = make("Frame", {
                Position = UDim2.new(0, MARGIN + 145, 0, TOPBAR_H - 6),
                Size = UDim2.new(0, 270, 0, height),
                BackgroundColor3 = Theme.ControlBg,
                BorderSizePixel = 0,
                ZIndex = 52,
                Parent = root,
            })
            corner(list, 4)
            stroke(list, Theme.ControlBorder, 0.2)
            make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
            make("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent = list,
            })
            if #hits == 0 then
                make("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundTransparency = 1,
                    Font = FONT,
                    Text = "No results",
                    TextSize = 12,
                    TextColor3 = Theme.TextDim,
                    ZIndex = 53,
                    Parent = list,
                })
            end
            for index, entry in ipairs(hits) do
                local item = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = index,
                    ZIndex = 53,
                    Parent = list,
                })
                local itemLabel = make("TextLabel", {
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Font = FONT,
                    Text = textValue(entry.tab.Name, "Tab") .. "  >  " .. textValue(entry.group.Name, "Group") .. "  >  " .. textValue(entry.text, ""),
                    TextSize = 12,
                    TextColor3 = Theme.TextMid,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 53,
                    Parent = item,
                })
                item.MouseEnter:Connect(function() tween(itemLabel, { TextColor3 = Theme.TextBright }, 0.1) end)
                item.MouseLeave:Connect(function() tween(itemLabel, { TextColor3 = Theme.TextMid }, 0.1) end)
                item.MouseButton1Click:Connect(function()
                    searchBox.Text = ""
                    closeOverlay()
                    setActiveTab(entry.tab)
                    task.delay(0.05, function()
                        if not entry.row.Parent then return end
                        local page = entry.tab.Page
                        local rowY = entry.row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
                        page.CanvasPosition = Vector2.new(0, math.max(0, rowY - 80))
                        flashRow(entry.row)
                    end)
                end)
            end
        end, function()
            if token ~= searchToken then return end
        end)
    end

    track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchClear.Visible = searchBox.Text ~= ""
        runSearch(searchBox.Text)
    end))

    local menuVisible = true
    local fadeCache
    local fadeLock = 0
    setMenuVisible = function(visible)
        visible = visible == true
        if visible == menuVisible or os.clock() < fadeLock then return end
        fadeLock = os.clock() + 0.2
        menuVisible = visible
        launcher.Visible = not visible
        if not visible then
            closeOverlay()
            hideTooltip()
            fadeCache = collectFade(win)
            for _, entry in ipairs(fadeCache) do
                tween(entry.instance, { [entry.property] = 1 }, 0.14)
            end
            task.delay(0.15, function()
                if not menuVisible then win.Visible = false end
            end)
        else
            win.Visible = true
            if fadeCache then
                for _, entry in ipairs(fadeCache) do
                    tween(entry.instance, { [entry.property] = entry.value }, 0.16)
                end
            end
        end
    end

    function self.ToggleMenu()
        setMenuVisible(not menuVisible)
    end

    function self.SetMenuVisible(visible)
        setMenuVisible(visible)
    end

    function self.SetMenuKey(keyCode)
        menuKey = keyCode
    end

    function self.SetTheme(name)
        return ThemeManager.Apply(name, screen)
    end

    function self.GetTheme()
        return Theme.Current
    end

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or controlListening then return end
        if menuKey and input.KeyCode == menuKey then
            self.ToggleMenu()
        end
    end))

    local function encodeValue(value)
        if typeof(value) == "Color3" then
            return { __color = { value.R, value.G, value.B } }
        end
        return value
    end

    local function decodeValue(value)
        if type(value) == "table" and type(value.__color) == "table" then
            return Color3.new(value.__color[1], value.__color[2], value.__color[3])
        end
        return value
    end

    function self.SaveConfig(name)
        if not canUseFiles() or not HttpService then return false end
        ensureFolder()
        local output = {}
        for flag, value in pairs(Vision.Flags) do output[flag] = encodeValue(value) end
        local ok = pcall(function()
            writefile(
                CONFIG_FOLDER .. "/configs/" .. configName(name) .. ".json",
                HttpService:JSONEncode(output)
            )
        end)
        return ok
    end

    function self.LoadConfig(name)
        if not canUseFiles() or not HttpService then return false end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/configs/" .. configName(name) .. ".json"))
        end)
        if not ok or type(data) ~= "table" then return false end
        for flag, value in pairs(data) do
            local binding = flagBinds[flag]
            if binding then
                pcall(binding.set, decodeValue(value))
            else
                Vision.Flags[flag] = decodeValue(value)
            end
        end
        return true
    end

    function self.ListConfigs()
        local names = {}
        if type(listfiles) ~= "function" then return names end
        ensureFolder()
        pcall(function()
            for _, path in ipairs(listfiles(CONFIG_FOLDER .. "/configs")) do
                local name = string.match(path, "([^/\\]+)%.json$")
                if name then names[#names + 1] = name end
            end
        end)
        table.sort(names)
        return names
    end

    Runtime[RUNTIME_KEY] = self
    self.Flags = Vision.Flags
    self.Window = win
    self.Theme = Theme
    self.Themes = ThemePresets
    self.ThemeManager = {
        Set = function(name) return ThemeManager.Apply(name, screen) end,
        Apply = function(name) return ThemeManager.Apply(name, screen) end,
        Get = ThemeManager.Get,
        List = ThemeManager.List,
    }
    self.ThemeNames = ThemeManager.List()
    return self
end

return Vision
