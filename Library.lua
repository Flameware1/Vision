local Vision = {}
Vision.Version = "1.0.0"
Vision.Flags = {}

-- ═══════════════════════════════════════════════════════════════
--  AUTO-SAVE API
--  Vision._scheduleSave()  — call after any flag change (debounced)
--  Vision._forceSave()     — save immediately (player leaving)
--  Vision._startAutoSave() — begin periodic + leave-hook saves
-- ═══════════════════════════════════════════════════════════════
local _savePending = false
local _saveFunc = nil  -- set later inside Window()

function Vision._scheduleSave()
	if _savePending then return end
	_savePending = true
	task.delay(1, function()
		_savePending = false
		if _saveFunc then pcall(_saveFunc) end
	end)
end

function Vision._forceSave()
	if _saveFunc then pcall(_saveFunc) end
end

local function getService(name)
	local ok, svc = pcall(function()
		return game:GetService(name)
	end)
	if ok and svc then
		if type(cloneref) == "function" then
			local ok2, c = pcall(cloneref, svc)
			if ok2 and c then
				return c
			end
		end
		return svc
	end
	return nil
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")
local HttpService = getService("HttpService")

local function localPlayer()
	return Players and Players.LocalPlayer
end

local function getGuiParent()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	if type(get_hidden_gui) == "function" then
		local ok, h = pcall(get_hidden_gui)
		if ok and h then return h end
	end
	if CoreGui then
		return CoreGui
	end
	local lp = localPlayer()
	if lp then
		return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
	end
	return nil
end

local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif type(protectgui) == "function" then
			protectgui(gui)
		end
	end)
end

local function resolveIcon(icon)
	if not icon or icon == 0 or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		return { Image = "rbxassetid://" .. tostring(math.floor(icon)) }
	end
	if type(icon) == "string" then
		if string.match(icon, "^%d+$") then
			return { Image = "rbxassetid://" .. icon }
		end
		if string.find(icon, "rbxassetid://") == 1 or string.sub(icon, 1, 4) == "http" then
			return { Image = icon }
		end
	end
	return nil
end

local function applyIcon(image, spec)
	if not spec or not spec.Image then
		image.Image = ""
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

local ASSET_BASE = "https://raw.githubusercontent.com/Flameware1/Vision/main/assets/"

local function customAssetFn()
	if type(getcustomasset) == "function" then return getcustomasset end
	if type(getsynasset) == "function" then return getsynasset end
	if syn and type(syn.getcustomasset) == "function" then
		return function(p) return syn.getcustomasset(p) end
	end
	return nil
end

local PNG_MAGIC = "\137PNG\r\n\26\n"
local remoteImageCache = {}
local function remoteImage(filename)
	if remoteImageCache[filename] ~= nil then
		return remoteImageCache[filename] or nil
	end
	remoteImageCache[filename] = false
	local getAsset = customAssetFn()
	if not getAsset or type(writefile) ~= "function" then return nil end
	pcall(function()
		local valid = false
		if type(isfile) == "function" and isfile(filename) and type(readfile) == "function" then
			local head = readfile(filename)
			valid = type(head) == "string" and string.sub(head, 1, 8) == PNG_MAGIC
		end
		if not valid then
			local body = game:HttpGet(ASSET_BASE .. filename)
			if type(body) ~= "string" or string.sub(body, 1, 8) ~= PNG_MAGIC then
				return
			end
			writefile(filename, body)
		end
		remoteImageCache[filename] = getAsset(filename)
	end)
	return remoteImageCache[filename] or nil
end

local LOGO_URL = "https://raw.githubusercontent.com/Flameware1/Vision/main/Vision.png"
local STRIPES_FILE = "vision_stripes_v1.png"
local TICK_FILE = "vision_tick_v1.png"

local Themes = {
	Dark = {
		Accent = Color3.fromRGB(56, 150, 255),
		AccentDark = Color3.fromRGB(18, 55, 110),
		HeaderMid = Color3.fromRGB(77, 102, 128),
		GradientTop = Color3.new(1, 1, 1),
		WindowBg = Color3.fromRGB(10, 10, 10),
		ChromeBg = Color3.fromRGB(4, 4, 4),
		PanelBg = Color3.fromRGB(16, 16, 18),
		ControlBg = Color3.fromRGB(24, 23, 27),
		ControlBorder = Color3.fromRGB(48, 46, 52),
		Track = Color3.fromRGB(30, 30, 30),
		TextWhite = Color3.fromRGB(235, 235, 238),
		TextBright = Color3.fromRGB(205, 205, 208),
		TextMid = Color3.fromRGB(140, 140, 144),
		TextDim = Color3.fromRGB(86, 86, 90),
		Check = Color3.fromRGB(10, 10, 10),
		InfoBg = Color3.fromRGB(235, 235, 238),
		InfoText = Color3.fromRGB(15, 15, 15),
	},
	Light = {
		Accent = Color3.fromRGB(56, 150, 255),
		AccentDark = Color3.fromRGB(56, 150, 255),
		HeaderMid = Color3.fromRGB(180, 210, 250),
		GradientTop = Color3.new(1, 1, 1),
		WindowBg = Color3.fromRGB(238, 238, 243),
		ChromeBg = Color3.fromRGB(220, 220, 228),
		PanelBg = Color3.fromRGB(250, 250, 255),
		ControlBg = Color3.fromRGB(235, 235, 240),
		ControlBorder = Color3.fromRGB(190, 190, 200),
		Track = Color3.fromRGB(218, 218, 226),
		TextWhite = Color3.fromRGB(18, 18, 24),
		TextBright = Color3.fromRGB(36, 36, 48),
		TextMid = Color3.fromRGB(120, 120, 130),
		TextDim = Color3.fromRGB(165, 165, 175),
		Check = Color3.fromRGB(250, 250, 255),
		InfoBg = Color3.fromRGB(18, 18, 24),
		InfoText = Color3.fromRGB(240, 240, 245),
	},
	Blue = {
		Accent = Color3.fromRGB(30, 130, 255),
		AccentDark = Color3.fromRGB(10, 50, 120),
		HeaderMid = Color3.fromRGB(64, 102, 153),
		GradientTop = Color3.new(1, 1, 1),
		WindowBg = Color3.fromRGB(8, 12, 20),
		ChromeBg = Color3.fromRGB(3, 5, 10),
		PanelBg = Color3.fromRGB(12, 16, 26),
		ControlBg = Color3.fromRGB(18, 22, 34),
		ControlBorder = Color3.fromRGB(40, 44, 60),
		Track = Color3.fromRGB(24, 28, 40),
		TextWhite = Color3.fromRGB(230, 235, 245),
		TextBright = Color3.fromRGB(200, 210, 225),
		TextMid = Color3.fromRGB(130, 140, 160),
		TextDim = Color3.fromRGB(80, 88, 105),
		Check = Color3.fromRGB(8, 12, 20),
		InfoBg = Color3.fromRGB(230, 235, 245),
		InfoText = Color3.fromRGB(15, 15, 15),
	},
	Rose = {
		Accent = Color3.fromRGB(236, 110, 180),
		AccentDark = Color3.fromRGB(110, 24, 63),
		HeaderMid = Color3.fromRGB(160, 100, 128),
		GradientTop = Color3.new(1, 1, 1),
		WindowBg = Color3.fromRGB(14, 8, 10),
		ChromeBg = Color3.fromRGB(8, 3, 5),
		PanelBg = Color3.fromRGB(20, 12, 16),
		ControlBg = Color3.fromRGB(28, 18, 22),
		ControlBorder = Color3.fromRGB(52, 36, 42),
		Track = Color3.fromRGB(34, 24, 28),
		TextWhite = Color3.fromRGB(240, 230, 236),
		TextBright = Color3.fromRGB(210, 195, 205),
		TextMid = Color3.fromRGB(145, 130, 140),
		TextDim = Color3.fromRGB(90, 78, 85),
		Check = Color3.fromRGB(14, 8, 10),
		InfoBg = Color3.fromRGB(240, 230, 236),
		InfoText = Color3.fromRGB(15, 15, 15),
	},
	Amethyst = {
		Accent = Color3.fromRGB(160, 80, 255),
		AccentDark = Color3.fromRGB(60, 20, 110),
		HeaderMid = Color3.fromRGB(130, 100, 165),
		GradientTop = Color3.new(1, 1, 1),
		WindowBg = Color3.fromRGB(12, 8, 20),
		ChromeBg = Color3.fromRGB(6, 3, 10),
		PanelBg = Color3.fromRGB(18, 12, 28),
		ControlBg = Color3.fromRGB(26, 18, 38),
		ControlBorder = Color3.fromRGB(50, 36, 62),
		Track = Color3.fromRGB(32, 22, 44),
		TextWhite = Color3.fromRGB(235, 225, 250),
		TextBright = Color3.fromRGB(210, 195, 230),
		TextMid = Color3.fromRGB(145, 130, 165),
		TextDim = Color3.fromRGB(88, 78, 105),
		Check = Color3.fromRGB(12, 8, 20),
		InfoBg = Color3.fromRGB(235, 225, 250),
		InfoText = Color3.fromRGB(15, 15, 15),
	},
}

-- Copy Dark as the current active theme
local Theme = {}
local currentThemeName = "Dark"
for k, v in pairs(Themes.Dark) do
	Theme[k] = v
end

local WIN_W = 660
local WIN_H = 620
local TOPBAR_H = 56
local FOOTER_H = 30
local MARGIN = 16
local COL_GAP = 14
local COL_W = math.floor((WIN_W - MARGIN * 2 - COL_GAP) / 2)
local HEAD_H = 26
local ROW_H = 26
local TEXT = 13

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function tween(obj, props, dur, style, dir)
	if not obj then return end
	local t = TweenService:Create(obj, TweenInfo.new(dur or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(parent, r)
	return make("UICorner", { CornerRadius = UDim.new(0, r or 3), Parent = parent })
end

local function stroke(parent, color, transparency)
	return make("UIStroke", {
		Color = color or Theme.ControlBorder,
		Thickness = 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function keyName(keyCode)
	if not keyCode then return "None" end
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
local function canFile()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		pcall(function()
			if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
			if not isfolder(CONFIG_FOLDER .. "/configs") then makefolder(CONFIG_FOLDER .. "/configs") end
		end)
	end
end

function Vision.Window(opts)
	opts = opts or {}
	local self = {}
	local title = opts.title or "VISION"
	local menuKey = opts.keybind or Enum.KeyCode.KeypadZero

	-- Apply a custom accent override if passed via opts
	if opts.accent then
		Theme.Accent = opts.accent
		currentThemeName = "Custom"
	end

	-- ================================================================
	-- Cleanup: destroy any existing Vision UI before creating a new one
	-- ================================================================
	local function _scanAndDestroy(parent)
		if not parent then return end
		for _, child in ipairs(parent:GetChildren()) do
			local ok1 = pcall(function()
				if child:GetAttribute("Vision") == true then
					child:Destroy()
				end
			end)
			local ok2 = pcall(function()
				_scanAndDestroy(child)
			end)
		end
	end
	pcall(function()
		for _, finder in ipairs({ gethui, get_hidden_gui }) do
			if type(finder) == "function" then
				local ok, container = pcall(finder)
				if ok and container then _scanAndDestroy(container) end
			end
		end
	end)
	pcall(function()
		if CoreGui then _scanAndDestroy(CoreGui) end
		local lp = localPlayer()
		if lp then _scanAndDestroy(lp:FindFirstChildOfClass("PlayerGui")) end
	end)
	-- Also destroy any stored reference from previous Window calls
	if Vision._activeGui then
		pcall(function() Vision._activeGui.Folder:Destroy() end)
		Vision._activeGui = nil
	end

	-- ================================================================
	-- Hide: nest ScreenGui inside a random-named Folder deep in gethui
	-- ================================================================
	local parent = getGuiParent()
	local rng = Random.new()
	local hex = string.format("%08X", rng:NextInteger(0, 4294967295))
	local folderName = "LocaleData_" .. hex
	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent
	pcall(function()
		folder:SetAttribute("Vision", true)
	end)

	local screen = make("ScreenGui", {
		Name = "Gui_" .. hex,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	pcall(function()
		screen:SetAttribute("Vision", true)
	end)
	protectGui(screen)
	screen.Parent = folder
	self.Gui = screen
	Vision._activeGui = { Screen = screen, Folder = folder }

	local conns = {}
	local function trackConn(c)
		conns[#conns + 1] = c
		return c
	end
	local themeRepaints = {}
	local function registerRepaint(fn)
		themeRepaints[#themeRepaints + 1] = fn
	end
	local keybindListenCancel = nil
	local anyListening = false
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
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		conns = {}
		flagBinds = {}
		pcall(function() folder:Destroy() end)
		Vision._activeGui = nil
	end

	local function viewport()
		local cam = workspace.CurrentCamera
		if cam and cam.ViewportSize.X > 100 then
			return cam.ViewportSize
		end
		return Vector2.new(1280, 720)
	end

	local vp = viewport()
	local win = make("Frame", {
		Name = "Window",
		Position = UDim2.new(0, math.max(20, math.floor((vp.X - WIN_W) / 2)), 0, math.max(20, math.floor((vp.Y - WIN_H) / 2))),
		Size = UDim2.new(0, WIN_W, 0, WIN_H),
		BackgroundColor3 = Theme.WindowBg,
		BorderSizePixel = 0,
		Parent = screen,
	})
	corner(win, 6)
	stroke(win, Theme.ControlBorder, 0.4)

	local topbar = make("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		Parent = win,
	})
	make("Frame", {
		Name = "TopDivider",
		Position = UDim2.new(0, MARGIN, 0, TOPBAR_H - 1),
		Size = UDim2.new(1, -MARGIN * 2, 0, 1),
		BackgroundColor3 = Theme.ControlBorder,
		BorderSizePixel = 0,
		Parent = win,
	})

	local logo = make("ImageLabel", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 2, 0.5, 0),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Parent = topbar,
	})
	-- Load logo: prefer cached local copy, download if missing, fall back to direct URL
	local logoFile = "vision_logo_v1.png"
	local logoLoaded = false
	local getAsset = customAssetFn()
	if getAsset and type(writefile) == "function" then
		if type(isfile) == "function" and isfile(logoFile) and type(readfile) == "function" then
			local head = readfile(logoFile)
			if type(head) == "string" and string.sub(head, 1, 8) == PNG_MAGIC then
				local asset = getAsset(logoFile)
				if asset then logo.Image = asset; logoLoaded = true end
			end
		end
		if not logoLoaded then
			pcall(function()
				local body = game:HttpGet(LOGO_URL)
				if type(body) == "string" and string.sub(body, 1, 8) == PNG_MAGIC then
					writefile(logoFile, body)
					local asset = getAsset(logoFile)
					if asset then logo.Image = asset; logoLoaded = true end
				end
			end)
		end
	end
	if not logoLoaded then
		pcall(function() logo.Image = LOGO_URL end)
	end

	make("Frame", {
		Name = "LogoDivider",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 44, 0.5, 0),
		Size = UDim2.new(0, 1, 0, 30),
		BackgroundColor3 = Theme.ControlBorder,
		BorderSizePixel = 0,
		Parent = topbar,
	})

	-- Search icon
	local searchIcon = make("ImageLabel", {
		Name = "SearchIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 58, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundTransparency = 1,
		Image = "rbxassetid://7733960988",
		ImageColor3 = Theme.TextDim,
		ScaleType = Enum.ScaleType.Fit,
		Parent = topbar,
	})

	local searchBox = make("TextBox", {
		Name = "SearchBox",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 78, 0.5, 0),
		Size = UDim2.new(0, 96, 0, 24),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "",
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.TextDim,
		TextSize = TEXT,
		TextColor3 = Theme.TextBright,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = topbar,
	})

	-- Horizontal scrollable tab navigation
	local NAV_START_X = MARGIN + 188  -- after logo + divider + search
	local tabScroll = make("ScrollingFrame", {
		Name = "TabScroll",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, NAV_START_X, 0.5, 0),
		Size = UDim2.new(1, -NAV_START_X - MARGIN, 0, TOPBAR_H - 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = topbar,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 24),
		Parent = tabScroll,
	})
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = tabScroll,
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
	-- Footer bar
	make("Frame", {
		Position = UDim2.new(0, MARGIN, 0, 0),
		Size = UDim2.new(1, -MARGIN * 2, 0, 1),
		BackgroundColor3 = Theme.ControlBorder,
		BorderSizePixel = 0,
		Parent = footer,
	})
	-- Footer globe icon
	local globe = make("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN, 0.5, 0),
		Size = UDim2.new(0, 13, 0, 13),
		BackgroundTransparency = 1,
		Image = "rbxassetid://92188766517878",
		ImageColor3 = Theme.TextDim,
		ScaleType = Enum.ScaleType.Fit,
		Parent = footer,
	})
	make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 19, 0.5, 0),
		Size = UDim2.new(0, 160, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = opts.footerText or ("Vision v" .. Vision.Version),
		TextSize = 12,
		TextColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = footer,
	})
	-- Key expiry timer (centered in footer, shown only when Keysystem is enabled)
	local keyTimerLbl = nil
	if opts.Keysystem then
		keyTimerLbl = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 140, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = "Key:24h",
			TextSize = 12,
			TextColor3 = Theme.TextDim,
			Parent = footer,
		})
	end

	local menuKeyLbl = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -MARGIN, 0.5, 0),
		Size = UDim2.new(0, 200, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "Menu: " .. keyName(menuKey),
		TextSize = 12,
		TextColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
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
	local overlayContent = nil
	local overlayOwnerClose = nil

	local function closeOverlay()
		if overlayContent then
			overlayContent:Destroy()
			overlayContent = nil
		end
		overlay.Visible = false
		if overlayOwnerClose then
			local cb = overlayOwnerClose
			overlayOwnerClose = nil
			cb()
		end
	end

	local function openOverlay(buildFn, onClose)
		closeOverlay()
		overlayOwnerClose = onClose
		overlayContent = make("Frame", {
			Name = "OverlayContent",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 51,
			Parent = overlay,
		})
		overlay.Visible = true
		buildFn(overlayContent)
	end

	overlayBlock.MouseButton1Click:Connect(function()
		closeOverlay()
	end)

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
	corner(tooltip, 3)
	stroke(tooltip, Theme.ControlBorder, 0.3)
	local tooltipLbl = make("TextLabel", {
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
		Parent = tooltipLbl,
	})

	local function showTooltip(text, anchor)
		tooltipLbl.Text = text
		local ap = anchor.AbsolutePosition
		local wp = win.AbsolutePosition
		tooltip.Position = UDim2.new(0, ap.X - wp.X - 4, 0, ap.Y - wp.Y + 20)
		tooltip.Visible = true
	end
	local function hideTooltip()
		tooltip.Visible = false
	end

	do
		local dragging = false
		local startPos, startMouse
		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				startMouse = input.Position
				startPos = win.Position
			end
		end)
		trackConn(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end))
		trackConn(UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and win.Visible then
				local delta = input.Position - startMouse
				win.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end))
	end

	local fadeProps = {
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
		local list = {}
		if not root or not root.Parent then
			return list
		end
		local ok = pcall(function()
			local function grab(inst)
				if not inst then return end
				local props = fadeProps[inst.ClassName]
				if props then
					for _, p in ipairs(props) do
						list[#list + 1] = { inst = inst, prop = p, value = inst[p] }
					end
				end
			end
			grab(root)
			for _, d in ipairs(root:GetDescendants()) do
				grab(d)
			end
		end)
		return list
	end

	-- Forward-declare tab/page state so key-system closures can capture them
	local tabs = {}
	local activeTab = nil
	local setActiveTab

	-- ================================================================
	-- Key System — encapsulated for anti-detection
	-- ================================================================
	local Key = {}
	Key.KEY_REQUIRED = "Vision-0x9"
	Key.locked = false
	Key.expiry = 0
	Key.tickerSeq = 0
	Key.fadeSeq = 0
	Key.file = CONFIG_FOLDER .. "/key.dat"
	Key.durHours = 24
	Key.durMins = 0
	Key.maxSecs = 86400
	Key.panel = nil
	Key.input = nil
	Key.inputBox = nil
	Key.redeemBtn = nil
	Key.getBtn = nil
	Key.errorLbl = nil

	Key.format = function(sec)
		if sec <= 0 then return "Key:Expired" end
		local hours = math.floor(sec / 3600)
		if hours >= 1 then
			return "Key:" .. hours .. "h " .. math.floor((sec % 3600) / 60) .. "m"
		else
			return "Key:" .. math.floor(sec / 60) .. "m " .. math.floor(sec % 60) .. "s"
		end
	end

	Key.startTicker = function()
		local s = Key.tickerSeq
		task.spawn(function()
			while s == Key.tickerSeq do
				if Key.locked then
					keyTimerLbl.Text = Key.format(Key.maxSecs)
				elseif Key.expiry > 0 then
					keyTimerLbl.Text = Key.format(Key.expiry - os.time())
				end
				local remaining = math.max(0, (Key.expiry or 0) - os.time())
				if remaining > 0 and remaining < 3600 then task.wait(1) else task.wait(30) end
			end
		end)
	end

	Key.reveal = function()
		if not Key.panel then return end
		Key.panel.Visible = true
		Key.input.Text = ""
		Key.inputBox.Interactable = true
		Key.redeemBtn.Interactable = true
		Key.getBtn.Interactable = true
		Key.errorLbl.Text = ""
		pcall(function()
			Key.panel.BackgroundTransparency = 0
			for _, d in ipairs(Key.panel:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextBox") then d.TextTransparency = 0
				elseif d:IsA("Frame") and d.Name ~= "KeyPanel" then d.BackgroundTransparency = 0
				elseif d:IsA("ImageLabel") then d.ImageTransparency = 0
				elseif d:IsA("UIStroke") then d.Transparency = 0
				end
			end
		end)
	end

	Key.tryRedeem = function()
		if (Key.input and Key.input.Text or "") == Key.KEY_REQUIRED then
			Key.inputBox.Interactable = false
			Key.redeemBtn.Interactable = false
			Key.getBtn.Interactable = false
			Key.errorLbl.Text = ""
			Key.expiry = os.time() + Key.maxSecs
			Key.locked = false
			if canFile() then
				pcall(function() writefile(Key.file, tostring(Key.expiry)) end)
			end
			local fs = Key.fadeSeq
			for _, d in ipairs(Key.panel:GetDescendants()) do
				pcall(function()
					if d:IsA("TextLabel") or d:IsA("TextBox") then tween(d, { TextTransparency = 1 }, 0.35)
					elseif d:IsA("Frame") and d.Name ~= "KeyPanel" then tween(d, { BackgroundTransparency = 1 }, 0.35)
					end
				end)
			end
			task.delay(0.4, function()
				if fs ~= Key.fadeSeq then return end
				Key.panel.Visible = false
				if tabs and #tabs > 0 then setActiveTab(tabs[1]) end
			end)
		else
			Key.errorLbl.Text = "Invalid key"
			tween(Key.inputBox, { BackgroundColor3 = Color3.fromRGB(60, 20, 20) }, 0.1)
			task.delay(0.18, function() tween(Key.inputBox, { BackgroundColor3 = Theme.ControlBg }, 0.25) end)
		end
	end

	Key.destroy = function()
		Key.fadeSeq = Key.fadeSeq + 1
		Key.tickerSeq = Key.tickerSeq + 1
		if canFile() then pcall(function() if isfile(Key.file) then delfile(Key.file) end end) end
		Key.expiry = 0
		Key.locked = true
		closeOverlay()
		hideTooltip()
		for _, tb in ipairs(tabs) do if tb and tb.Page then tb.Page.Visible = false end end
		activeTab = nil
		Key.reveal()
		Key.startTicker()
	end

	-- === Activate key system if enabled ===
	if opts.Keysystem then
		Key.locked = true
		local d = opts.KeyDuration or {}
		Key.durHours = math.clamp(d.Hours or 24, 0, 48)
		Key.durMins = math.clamp(d.Minutes or 0, 0, 59)
		Key.maxSecs = (Key.durHours * 3600) + (Key.durMins * 60)

		-- Read saved expiry
		if canFile() then
			pcall(function()
				if isfile(Key.file) then Key.expiry = tonumber(readfile(Key.file)) or 0 end
			end)
		end

		if Key.expiry > os.time() then
			Key.locked = false
			Key.startTicker()
		else
			-- ============================================================
			-- Build key entry panel
			-- ============================================================
			Key.panel = make("Frame", {
				Name = "KeyPanel", AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -14),
				Size = UDim2.new(0, 256, 0, 200),
				BackgroundColor3 = Theme.PanelBg, BorderSizePixel = 0,
				ZIndex = 40, Parent = content,
			})
			corner(Key.panel, 5)
			stroke(Key.panel, Theme.ControlBorder, 0.3)

			make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18),
				Size = UDim2.new(1, -28, 0, 22), BackgroundTransparency = 1,
				Font = FONT_BOLD, Text = "Vision Key", TextSize = 15,
				TextColor3 = Theme.TextWhite, ZIndex = 41, Parent = Key.panel,
			})

			Key.inputBox = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52),
				Size = UDim2.new(1, -32, 0, 34), BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0, ZIndex = 41, Parent = Key.panel,
			})
			corner(Key.inputBox, 4)
			stroke(Key.inputBox, Theme.ControlBorder, 0.25)

			Key.input = make("TextBox", {
				Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
				BackgroundTransparency = 1, Font = FONT,
				PlaceholderText = "Enter key...", PlaceholderColor3 = Theme.TextDim,
				Text = "", TextSize = 13, TextColor3 = Theme.TextWhite,
				TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
				ZIndex = 42, Parent = Key.inputBox,
			})

			Key.errorLbl = make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92),
				Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1,
				Font = FONT, Text = "", TextSize = 11,
				TextColor3 = Color3.fromRGB(255, 72, 72), ZIndex = 41, Parent = Key.panel,
			})

			-- Redeem
			Key.redeemBtn = make("Frame", {
				Name = "KeyRedeem", AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.new(1, -32, 0, 32),
				BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
				ZIndex = 41, Parent = Key.panel,
			})
			corner(Key.redeemBtn, 4)
			local rdrStroke = stroke(Key.redeemBtn, Theme.Accent, 0.15)
			local rdrLbl = make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Font = FONT_BOLD, Text = "Redeem", TextSize = 13,
				TextColor3 = Theme.Check, ZIndex = 41, Parent = Key.redeemBtn,
			})
			Key.redeemBtn.MouseEnter:Connect(function()
				tween(Key.redeemBtn, { BackgroundColor3 = Theme.TextWhite }, 0.13)
				tween(rdrStroke, { Color = Theme.TextWhite }, 0.13)
				tween(rdrLbl, { TextColor3 = Theme.Check }, 0.13)
			end)
			Key.redeemBtn.MouseLeave:Connect(function()
				tween(Key.redeemBtn, { BackgroundColor3 = Theme.Accent }, 0.18)
				tween(rdrStroke, { Color = Theme.Accent }, 0.18)
				tween(rdrLbl, { TextColor3 = Theme.Check }, 0.18)
			end)
			Key.redeemBtn.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					tween(Key.redeemBtn, { Size = UDim2.new(1, -30, 0, 30) }, 0.05)
					task.delay(0.06, function() tween(Key.redeemBtn, { Size = UDim2.new(1, -32, 0, 32) }, 0.08) end)
					Key.tryRedeem()
				end
			end)

			-- Get Key
			Key.getBtn = make("Frame", {
				Name = "KeyGet", AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 152), Size = UDim2.new(1, -32, 0, 30),
				BackgroundColor3 = Theme.ControlBg, BorderSizePixel = 0,
				ZIndex = 41, Parent = Key.panel,
			})
			corner(Key.getBtn, 4)
			local gkStroke = stroke(Key.getBtn, Theme.ControlBorder, 0.25)
			local gkLbl = make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				Font = FONT, Text = "Get Key", TextSize = 12,
				TextColor3 = Theme.TextMid, ZIndex = 41, Parent = Key.getBtn,
			})
			Key.getBtn.MouseEnter:Connect(function()
				tween(Key.getBtn, { BackgroundColor3 = Theme.PanelBg }, 0.13)
				tween(gkStroke, { Color = Theme.TextMid }, 0.13)
				tween(gkLbl, { TextColor3 = Theme.TextBright }, 0.13)
			end)
			Key.getBtn.MouseLeave:Connect(function()
				tween(Key.getBtn, { BackgroundColor3 = Theme.ControlBg }, 0.18)
				tween(gkStroke, { Color = Theme.ControlBorder }, 0.18)
				tween(gkLbl, { TextColor3 = Theme.TextMid }, 0.18)
			end)
			Key.getBtn.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 and opts.GetKeyUrl then
					pcall(function() if setclipboard then setclipboard(opts.GetKeyUrl) end end)
				end
			end)

			Key.inputBox.MouseEnter:Connect(function()
				tween(Key.inputBox, { BackgroundColor3 = Theme.Track }, 0.1)
			end)
			Key.inputBox.MouseLeave:Connect(function()
				tween(Key.inputBox, { BackgroundColor3 = Theme.ControlBg }, 0.18)
			end)

			Key.input.FocusLost:Connect(function(enter) if enter then Key.tryRedeem() end end)

			Key.startTicker()
		end

		-- === Public: RenewKey ===
		function self.RenewKey() Key.destroy() end
	end

	-- Fallback for Keysystem off
	if not self.RenewKey then
		function self.RenewKey() return false end
	end

	-- Re-expose a locked-check for internal gates
	local function isKeyLocked()
		return opts.Keysystem and Key and Key.locked
	end

	win.Visible = true

	-- ================================================================
	-- Notification system
	-- ================================================================
	local notifications = make("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.new(0, 260, 1, -40),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = screen,
	})
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = notifications,
	})

	local noteOrder = 0
	function self.Notify(o)
		o = o or {}
		local title = o.title or "Vision"
		local body = o.text or o.body or ""
		local duration = o.duration or 5
		local noteType = o.type or "info"
		local colors = {
			info = Color3.fromRGB(56, 150, 255),
			success = Color3.fromRGB(46, 204, 113),
			warn = Color3.fromRGB(241, 196, 15),
			error = Color3.fromRGB(231, 76, 60),
		}
		local titleColor = colors[noteType] or colors.info

		noteOrder = noteOrder + 1
		local note = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.PanelBg,
			BorderSizePixel = 0,
			LayoutOrder = noteOrder,
			ZIndex = 31,
			Parent = notifications,
		})
		corner(note, 4)
		stroke(note, Theme.ControlBorder, 0.3)
		-- Title
		make("TextLabel", {
			Position = UDim2.new(0, 12, 0, 8),
			Size = UDim2.new(1, -24, 0, 14),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			Text = title,
			TextSize = 12,
			TextColor3 = titleColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 32,
			Parent = note,
		})
		-- Body (if present)
		local bodyLbl
		if body ~= "" then
			bodyLbl = make("TextLabel", {
				Position = UDim2.new(0, 12, 0, 24),
				Size = UDim2.new(1, -24, 0, 14),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = body,
				TextSize = 11,
				TextColor3 = Theme.TextMid,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				ZIndex = 32,
				Parent = note,
			})
		end
		make("UIPadding", {
			PaddingBottom = UDim.new(0, 10),
			Parent = note,
		})

		-- Fade in
		for _, d in ipairs(note:GetDescendants()) do
			pcall(function()
				if d:IsA("TextLabel") then
					d.TextTransparency = 1
				end
			end)
		end
		note.BackgroundTransparency = 1
		for _, d in ipairs(note:GetDescendants()) do
			pcall(function()
				if d:IsA("TextLabel") then
					tween(d, { TextTransparency = 0 }, 0.18)
				end
			end)
		end
		tween(note, { BackgroundTransparency = 0 }, 0.18)

		-- Fade out and destroy after duration
		task.delay(duration, function()
			for _, d in ipairs(note:GetDescendants()) do
				pcall(function()
					if d:IsA("TextLabel") then
						tween(d, { TextTransparency = 1 }, 0.2)
					elseif d:IsA("Frame") and d.Name ~= "Notifications" then
						tween(d, { BackgroundTransparency = 1 }, 0.2)
					end
				end)
			end
			task.delay(0.25, function()
				pcall(function() note:Destroy() end)
			end)
		end)

		return note
	end

	tabs = {}
	activeTab = nil
	local searchIndex = {}

	local switchGen = 0

	local function restorePage(tb)
		if tb.ActiveTweens then
			for _, tw in ipairs(tb.ActiveTweens) do
				pcall(function() tw:Cancel() end)
			end
		end
		tb.ActiveTweens = nil
		if tb.LastCache then
			for _, e in ipairs(tb.LastCache) do
				if e.inst and e.inst.Parent then
					e.inst[e.prop] = e.value
				end
			end
		end
		tb.LastCache = nil
	end

setActiveTab = function(t)
	if not t or not t.Page then return end
	if isKeyLocked() then return end
	if activeTab == t then return end
	closeOverlay()
		switchGen = switchGen + 1
		local gen = switchGen
		local old = activeTab
		local oi, ni = 0, 0
		for i, tb in ipairs(tabs) do
			if tb == old then oi = i end
			if tb == t then ni = i end
		end
		local dir = (oi ~= 0 and ni < oi) and -1 or 1

	if old then
		restorePage(old)
		if old.Page then old.Page.Visible = false end
		if old.NavIcon then tween(old.NavIcon, { ImageColor3 = Theme.TextDim }, 0.14) end
		if old.NavLabel then tween(old.NavLabel, { TextColor3 = Theme.TextDim }, 0.14) end
	end
	activeTab = t
	if t.NavIcon then tween(t.NavIcon, { ImageColor3 = Theme.Accent }, 0.14) end
	if t.NavLabel then tween(t.NavLabel, { TextColor3 = Theme.TextWhite }, 0.14) end

	restorePage(t)
	local cache = t.Page and collectFade(t.Page) or {}
		t.LastCache = cache
		t.ActiveTweens = {}
		for _, e in ipairs(cache) do
			e.inst[e.prop] = 1
		end
		t.Page.Position = UDim2.new(0, dir * 26, 0, 0)
		t.Page.Visible = true
		t.ActiveTweens[#t.ActiveTweens + 1] = tween(t.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)

		local byGroup = {}
		local groups = t.Groups or {}
		for _, e in ipairs(cache) do
			local box
		for _, gr in ipairs(groups) do
			if e.inst == gr.Box or e.inst:IsDescendantOf(gr.Box) then
				box = gr.Box
				break
			end
		end
		byGroup[box or t.Page] = byGroup[box or t.Page] or {}
		table.insert(byGroup[box or t.Page], e)
	end
	for gi, gr in ipairs(groups) do
			local entries = byGroup[gr.Box]
			if entries then
				task.delay(0.02 + gi * 0.03, function()
					if switchGen ~= gen or not t.ActiveTweens then return end
					for _, e in ipairs(entries) do
						t.ActiveTweens[#t.ActiveTweens + 1] = tween(e.inst, { [e.prop] = e.value }, 0.2, Enum.EasingStyle.Quad)
					end
				end)
			end
		end
		local loose = byGroup[t.Page]
		if loose then
			for _, e in ipairs(loose) do
				t.ActiveTweens[#t.ActiveTweens + 1] = tween(e.inst, { [e.prop] = e.value }, 0.18, Enum.EasingStyle.Quad)
			end
		end
		local groupCount = t.Groups and #t.Groups or 0
	task.delay(0.02 + groupCount * 0.03 + 0.24, function()
			if switchGen == gen then
				t.ActiveTweens = nil
				t.LastCache = nil
			end
		end)
	end

	function self.Tab(name, topts)
		-- Handle :Tab("Combat") convention: first arg is the window itself
		if name == self then
			name, topts = topts, nil
		end
		if type(name) == "table" then
			topts = name
			name = topts.Name or topts.name or topts.title or "Tab"
		end
		topts = topts or {}
		if type(name) ~= "string" then
			name = tostring(name)
		end
		local tab = {}
		tab.Name = name

		local nav = make("Frame", {
			Name = "Nav_" .. name,
			Size = UDim2.new(0, 30, 1, -12),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = #tabs + 1,
			Parent = tabScroll,
		})
		local navIcon = make("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			ImageColor3 = Theme.TextDim,
			ScaleType = Enum.ScaleType.Fit,
			Parent = nav,
		})
		local hasNavIcon = applyIcon(navIcon, resolveIcon(topts.icon or topts.Icon))
		if not hasNavIcon then
			navIcon.Visible = false
		end
		local navLbl = make("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, hasNavIcon and 21 or 0, 0.5, 0),
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = FONT_MED,
			Text = name,
			TextSize = TEXT,
			TextColor3 = Theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = nav,
		})

		local page = make("ScrollingFrame", {
			Name = "Page_" .. name,
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
		local colL = make("Frame", {
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
			Parent = colL,
		})
		local colR = make("Frame", {
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
			Parent = colR,
		})
		make("UIPadding", {
			PaddingBottom = UDim.new(0, 14),
			Parent = page,
		})

		tab.Page = page
		tab.NavIcon = navIcon
		tab.NavLabel = navLbl
		tab.ColL = colL
		tab.ColR = colR
		tab.Groups = {}

		nav.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				setActiveTab(tab)
			end
		end)
		nav.MouseEnter:Connect(function()
			if activeTab ~= tab then
				tween(navIcon, { ImageColor3 = Theme.TextMid }, 0.1)
				tween(navLbl, { TextColor3 = Theme.TextMid }, 0.1)
			end
		end)
		nav.MouseLeave:Connect(function()
			if activeTab ~= tab then
				tween(navIcon, { ImageColor3 = Theme.TextDim }, 0.1)
				tween(navLbl, { TextColor3 = Theme.TextDim }, 0.1)
			end
		end)

		function tab.Group(gname, gopts, goptsExtra)
			-- Handle :Group("Aimbot", opts): Lua passes (tab, "Aimbot", opts)
			if type(gname) == "table" and type(gopts) == "string" then
				gname, gopts = gopts, goptsExtra
			end
			if type(gname) == "table" then
				gopts = gname
				gname = gopts.Name or gopts.name or gopts.title or "Group"
			end
			gopts = gopts or {}
			if type(gname) ~= "string" then
				gname = tostring(gname)
			end
			local group = {}

			local side = gopts.side
			if side ~= "left" and side ~= "right" then
				local nl, nr = 0, 0
				for _, gr in ipairs(tab.Groups) do
					if gr.Side == "left" then nl = nl + 1 else nr = nr + 1 end
				end
				side = (nl <= nr) and "left" or "right"
			end
			local parentCol = (side == "left") and colL or colR

			local box = make("Frame", {
				Name = "Group_" .. gname,
				Size = UDim2.new(1, 0, 0, HEAD_H),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.PanelBg,
				BorderSizePixel = 0,
				Parent = parentCol,
			})
			corner(box, 3)

			local head = make("Frame", {
				Name = "Head",
				Size = UDim2.new(1, 0, 0, HEAD_H),
				BackgroundColor3 = Theme.AccentDark,
				BorderSizePixel = 0,
				Parent = box,
			})
			corner(head, 3)
			make("UIGradient", {
				Name = "ThemeGradient",
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.GradientTop),
					ColorSequenceKeypoint.new(0.55, Theme.HeaderMid),
					ColorSequenceKeypoint.new(1, Theme.AccentDark),
				}),
				Parent = head,
			})
			local stripesAsset = remoteImage(STRIPES_FILE)
			if stripesAsset then
				make("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = stripesAsset,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.new(0, 24, 0, 24),
					ImageTransparency = 0.45,
					ZIndex = 2,
					Parent = head,
				})
			end
			local headTitle = make("TextLabel", {
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -50, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_BOLD,
				Text = gname,
				TextSize = TEXT,
				TextColor3 = Theme.TextWhite,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
				Parent = head,
			})

			if gopts.info then
				local infoCircle = make("Frame", {
					Name = "InfoCircle",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 15, 0, 15),
					BackgroundColor3 = Theme.InfoBg,
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = head,
				})
				corner(infoCircle, 8)
				make("TextLabel", {
					Name = "InfoCircleText",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT_BOLD,
					Text = "!",
					TextSize = 11,
					TextColor3 = Theme.InfoText,
					ZIndex = 3,
					Parent = infoCircle,
				})
				infoCircle.MouseEnter:Connect(function()
					showTooltip(gopts.info, infoCircle)
				end)
				infoCircle.MouseLeave:Connect(function()
					hideTooltip()
				end)
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
				Padding = UDim.new(0, 4),
				Parent = body,
			})
			make("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				Parent = body,
			})

			group.Box = box
			group.Body = body
			group.Name = gname
			group.Side = side
			local elemOrder = 0
			local function nextOrder()
				elemOrder = elemOrder + 1
				return elemOrder
			end

			local function registerSearch(text, row)
				searchIndex[#searchIndex + 1] = {
					tab = tab,
					group = group,
					text = text,
					row = row,
				}
			end

			group._nextOrder = nextOrder
			group._registerSearch = registerSearch
			tab.Groups[#tab.Groups + 1] = group

			attachElements(group)

			return group
		end

		tab.Select = function()
			setActiveTab(tab)
		end

		tabs[#tabs + 1] = tab
		if not activeTab and not isKeyLocked() then
			setActiveTab(tab)
		end
		return tab
	end

	function attachElements(group)
		local body = group.Body
		local nextOrder = group._nextOrder
		local registerSearch = group._registerSearch

		local function baseRow(h)
			local row = make("Frame", {
				Size = UDim2.new(1, 0, 0, h),
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
				Parent = body,
			})
			return row
		end

		function group.Label(o)
			o = o or {}
			local row = baseRow(20)
			make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = o.text or "",
				TextSize = TEXT,
				TextColor3 = Theme.TextMid,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Parent = row,
			})
			return { Row = row }
		end

		function group.Toggle(o)
			o = o or {}
			local saved = o.flag and Vision.Flags[o.flag]
			local state = saved ~= nil and (saved and true or false) or (o.default and true or false)
			local ch, cs, cv = 0, 1, 1
			local hasColor = o.color ~= nil
			if hasColor and typeof(o.color) == "Color3" then
				ch, cs, cv = o.color:ToHSV()
			end

			local row = baseRow(22)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Toggle",
				TextSize = TEXT,
				TextColor3 = Theme.TextMid,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Toggle", row)

			local boxBtn = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 15, 0, 15),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(boxBtn, 3)
			local boxStroke = stroke(boxBtn, Theme.ControlBorder, 0)
			-- Check indicator icon
			local check = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 11, 0, 11),
				BackgroundTransparency = 1,
				Image = "rbxassetid://98454659316573",
				ImageColor3 = Theme.Check,
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = boxBtn,
			})

			local swatch
			if hasColor then
				swatch = make("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -21, 0.5, 0),
					Size = UDim2.new(0, 24, 0, 14),
					BackgroundColor3 = Color3.fromHSV(ch, cs, cv),
					BorderSizePixel = 0,
					Parent = row,
				})
				corner(swatch, 2)
				stroke(swatch, Theme.ControlBorder, 0.2)
			end

			local function paint()
				if state then
				tween(boxBtn, { BackgroundColor3 = Theme.Accent }, 0.14)
				tween(boxStroke, { Color = Theme.Accent }, 0.14)
				tween(check, { ImageTransparency = 0 }, 0.14)
				tween(lbl, { TextColor3 = Theme.TextBright }, 0.14)
			else
				tween(boxBtn, { BackgroundColor3 = Theme.ControlBg }, 0.14)
				tween(boxStroke, { Color = Theme.ControlBorder }, 0.14)
				tween(check, { ImageTransparency = 1 }, 0.14)
				tween(lbl, { TextColor3 = Theme.TextMid }, 0.14)
				end
			end
			paint()
			registerRepaint(paint)

			local function currentColor()
				return Color3.fromHSV(ch, cs, cv)
			end

			local function push(silent)
				if o.flag then Vision.Flags[o.flag] = state; Vision._scheduleSave() end
				if hasColor and o.colorFlag then Vision.Flags[o.colorFlag] = currentColor(); Vision._scheduleSave() end
				if not silent and o.callback then
					task.spawn(o.callback, state)
				end
			end

			local function set(v, silent)
				v = v and true or false
				if v == state then return end
				state = v
				paint()
				push(silent)
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if swatch then
						local x, y = input.Position.X, input.Position.Y
						local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
						if x >= sp.X and x <= sp.X + ss.X and y >= sp.Y and y <= sp.Y + ss.Y then
							return
						end
					end
					set(not state)
				end
			end)
			row.MouseEnter:Connect(function()
				if not state then
					tween(lbl, { TextColor3 = Theme.TextBright }, 0.1)
				end
			end)
			row.MouseLeave:Connect(function()
				if not state then
					tween(lbl, { TextColor3 = Theme.TextMid }, 0.1)
				end
			end)

			if swatch then
				swatch.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						openHuePopup(swatch, function() return ch end, function(h)
							ch, cs, cv = h, 1, 1
							swatch.BackgroundColor3 = currentColor()
							if o.colorFlag then Vision.Flags[o.colorFlag] = currentColor(); Vision._scheduleSave() end
							if o.colorCallback then
								task.spawn(o.colorCallback, currentColor())
							end
						end)
					end
				end)
			end

			push(true)
			bindFlag(o.flag, function(v) set(v, false) end, function() return state end)
			if hasColor and o.colorFlag then
				bindFlag(o.colorFlag, function(v)
					if typeof(v) == "Color3" then
						ch, cs, cv = v:ToHSV()
						swatch.BackgroundColor3 = currentColor()
					end
				end, currentColor)
			end

			return {
				Row = row,
				Set = set,
				Get = function() return state end,
				SetColor = hasColor and function(c)
					ch, cs, cv = c:ToHSV()
					swatch.BackgroundColor3 = currentColor()
				end or nil,
				GetColor = hasColor and currentColor or nil,
			}
		end

		function group.Keybind(o)
			o = o or {}
			local savedKey = o.flag and Vision.Flags[o.flag]
			local key = o.default
			-- Restore saved keybind (stored as string name like "Q" or "LeftShift")
			if type(savedKey) == "string" and savedKey ~= "None" then
				local ok, kc = pcall(function() return Enum.KeyCode[savedKey] end)
				if ok and kc then key = kc end
			elseif typeof(savedKey) == "EnumItem" then
				key = savedKey
			end
			local mode = o.mode or "Toggle"
			local listening = false
			local held = false

			local row = baseRow(22)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -80, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = o.text or "Keybind",
				TextSize = TEXT,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Keybind", row)
			local keyLbl = make("TextLabel", {
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

			local function stopListening()
				listening = false
				keyLbl.Text = "[ " .. keyName(key) .. " ]"
				tween(keyLbl, { TextColor3 = Theme.TextDim }, 0.1)
			end

			local function applyKey(kc)
				key = kc
				keyLbl.Text = "[ " .. keyName(key) .. " ]"
				if o.flag then Vision.Flags[o.flag] = key and key.Name or "None"; Vision._scheduleSave() end
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if keybindListenCancel then keybindListenCancel() end
					keybindListenCancel = stopListening
					anyListening = true
					listening = true
					keyLbl.Text = "[ ... ]"
					tween(keyLbl, { TextColor3 = Theme.Accent }, 0.1)
				end
			end)

			local function push(state)
				if o.callback then
					task.spawn(o.callback, state, key)
				end
			end

			trackConn(UserInputService.InputBegan:Connect(function(input, processed)
				if listening and not processed and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode ~= Enum.KeyCode.Escape then
						key = input.KeyCode
					else
						key = nil
					end
					keybindListenCancel = nil
					stopListening()
					task.defer(function() anyListening = false end)
					if o.flag then Vision.Flags[o.flag] = key and key.Name or "None"; Vision._scheduleSave() end
					if o.changed then
						task.spawn(o.changed, key)
					end
					return
				end
				if processed or listening or anyListening then return end
				if key and input.KeyCode == key then
					if mode == "Hold" then
						held = true
						push(true)
					else
						push(true)
					end
				end
			end))
			trackConn(UserInputService.InputEnded:Connect(function(input)
				if mode == "Hold" and key and input.KeyCode == key and held then
					held = false
					push(false)
				end
			end))

			if o.flag then Vision.Flags[o.flag] = key and key.Name or "None"; Vision._scheduleSave() end
			bindFlag(o.flag, function(v)
				if type(v) == "string" and v ~= "None" then
					local ok, kc = pcall(function() return Enum.KeyCode[v] end)
					applyKey(ok and kc or nil)
				else
					applyKey(nil)
				end
			end, function() return key and key.Name or "None" end)

			return {
				Row = row,
				Set = applyKey,
				Get = function() return key end,
			}
		end

		function group.Slider(o)
			o = o or {}
			local min = o.min or 0
			local max = o.max or 100
			local step = o.step or 1
			local decimals = o.decimals
			if decimals == nil then
				decimals = (step % 1 ~= 0) and 2 or 0
			end
			local saved = o.flag and Vision.Flags[o.flag]
			local value = math.clamp((type(saved) == "number" and saved) or (o.default or min), min, max)

			local row = baseRow(34)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -90, 0, 18),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Slider",
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Slider", row)
			local valueLbl = make("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 86, 0, 18),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = "",
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			local rail = make("Frame", {
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundColor3 = Theme.Track,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(rail, 2)
			local tickAsset = remoteImage(TICK_FILE)
			if tickAsset then
				make("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = tickAsset,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.new(0, 4, 1, 0),
					ImageTransparency = 0.35,
					ZIndex = 2,
					Parent = rail,
				})
			end
			local fill = make("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = rail,
			})
			fill.BackgroundColor3 = Theme.Accent
			corner(fill, 2)

			local function fmt(v)
				local s
				if decimals > 0 then
					s = string.format("%." .. decimals .. "f", v)
				else
					s = tostring(math.floor(v + 0.5))
				end
				return s .. (o.suffix or "")
			end

			local function paint()
				local alpha = (max > min) and (value - min) / (max - min) or 0
				valueLbl.Text = fmt(value)
				valueLbl.TextColor3 = Theme.TextBright
				fill.BackgroundColor3 = Theme.Accent
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				rail.BackgroundColor3 = Theme.Track
			end

			local function set(v, silent)
				v = math.clamp(v, min, max)
				v = min + math.floor((v - min) / step + 0.5) * step
				v = math.clamp(v, min, max)
				if v == value then
					paint()
					return
				end
				value = v
				paint()
				if o.flag then Vision.Flags[o.flag] = value; Vision._scheduleSave() end
				if not silent and o.callback then
					task.spawn(o.callback, value)
				end
			end
			registerRepaint(paint)

			local dragging = false
			local function fromX(x)
				local a = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				set(min + a * (max - min))
			end
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					fromX(input.Position.X)
				end
			end)
			trackConn(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end))
			trackConn(UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					fromX(input.Position.X)
				end
			end))

			paint()
			if o.flag then Vision.Flags[o.flag] = value; Vision._scheduleSave() end
			bindFlag(o.flag, function(v) set(v, false) end, function() return value end)

			return {
				Row = row,
				Set = set,
				Get = function() return value end,
			}
		end

		function group.Dropdown(o)
			o = o or {}
			local options = o.options or {}
			local multi = o.multi and true or false
			local selected
			local selectedSet = {}
			local savedVal = o.flag and Vision.Flags[o.flag]
			if multi then
				local src = (type(savedVal) == "table" and savedVal) or o.default or {}
				for _, v in ipairs(src) do
					selectedSet[v] = true
				end
			else
				selected = (savedVal ~= nil and savedVal) or o.default or options[1]
			end

			local row = baseRow(26)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -130, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Dropdown",
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Dropdown", row)

			local chevBtn = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 22, 0, 22),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(chevBtn, 3)
			local chev = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 11, 0, 11),
				BackgroundTransparency = 1,
				Image = "rbxassetid://124381193435292",
				ImageColor3 = Theme.TextMid,
				ScaleType = Enum.ScaleType.Fit,
				Parent = chevBtn,
			})

			local valBtn = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -24, 0.5, 0),
				Size = UDim2.new(0, 86, 0, 22),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(valBtn, 3)
			local valLbl = make("TextLabel", {
				Size = UDim2.new(1, -8, 1, 0),
				Position = UDim2.new(0, 4, 0, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = "",
				TextSize = 12,
				TextColor3 = Theme.TextBright,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = valBtn,
			})

			local function current()
				if multi then
					local parts = {}
					for _, opt in ipairs(options) do
						if selectedSet[opt] then parts[#parts + 1] = opt end
					end
					return parts
				end
				return selected
			end

			local function paintValue()
				if multi then
					local parts = current()
					valLbl.Text = #parts > 0 and table.concat(parts, ", ") or "None"
				else
					valLbl.Text = tostring(selected or "None")
				end
			end

			local function push(silent)
				if o.flag then Vision.Flags[o.flag] = current(); Vision._scheduleSave() end
				if not silent and o.callback then
					task.spawn(o.callback, current())
				end
			end

			local open = false
			local function openList()
				open = true
				tween(chev, { Rotation = 180 }, 0.15)
				openOverlay(function(root)
					local wp = win.AbsolutePosition
					local bp = valBtn.AbsolutePosition
					local listW = 130
					local listH = math.min(#options, 8) * 24 + 8
					local x = bp.X - wp.X + valBtn.AbsoluteSize.X - listW + 24
					local y = bp.Y - wp.Y + valBtn.AbsoluteSize.Y + 4
					if y + listH > WIN_H - FOOTER_H then
						y = bp.Y - wp.Y - listH - 4
					end
					local list = make("ScrollingFrame", {
						Position = UDim2.new(0, x, 0, y),
						Size = UDim2.new(0, listW, 0, listH),
						BackgroundColor3 = Theme.ControlBg,
						BorderSizePixel = 0,
						ScrollBarThickness = 2,
						ScrollBarImageColor3 = Theme.ControlBorder,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						ZIndex = 52,
						Parent = root,
					})
					corner(list, 3)
					stroke(list, Theme.ControlBorder, 0.2)
					make("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = list,
					})
					make("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
						Parent = list,
					})
					for i, opt in ipairs(options) do
						local item = make("TextButton", {
							Size = UDim2.new(1, 0, 0, 24),
							BackgroundTransparency = 1,
							Text = "",
							AutoButtonColor = false,
							LayoutOrder = i,
							ZIndex = 53,
							Parent = list,
						})
						local on = multi and selectedSet[opt] or (opt == selected)
						local il = make("TextLabel", {
							Position = UDim2.new(0, 10, 0, 0),
							Size = UDim2.new(1, -20, 1, 0),
							BackgroundTransparency = 1,
							Font = FONT,
							Text = opt,
							TextSize = 12,
							TextColor3 = on and Theme.Accent or Theme.TextMid,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = 53,
							Parent = item,
						})
						item.MouseEnter:Connect(function()
							local sel = multi and selectedSet[opt] or (opt == selected)
							if not sel then
								tween(il, { TextColor3 = Theme.TextBright }, 0.1)
							end
						end)
						item.MouseLeave:Connect(function()
							local sel = multi and selectedSet[opt] or (opt == selected)
							if not sel then
								tween(il, { TextColor3 = Theme.TextMid }, 0.1)
							end
						end)
						item.MouseButton1Click:Connect(function()
							if multi then
								selectedSet[opt] = not selectedSet[opt] or nil
								local sel = selectedSet[opt]
								tween(il, { TextColor3 = sel and Theme.Accent or Theme.TextMid }, 0.1)
								paintValue()
								push(false)
							else
								selected = opt
								paintValue()
								push(false)
								closeOverlay()
							end
						end)
					end
				end, function()
					open = false
					tween(chev, { Rotation = 0 }, 0.15)
				end)
			end

			local function clickOpen(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if open then
						closeOverlay()
					else
						openList()
					end
				end
			end
			valBtn.InputBegan:Connect(clickOpen)
			chevBtn.InputBegan:Connect(clickOpen)

			paintValue()
			push(true)
			bindFlag(o.flag, function(v)
				if multi and type(v) == "table" then
					selectedSet = {}
					for _, x in ipairs(v) do selectedSet[x] = true end
				elseif not multi then
					selected = v
				end
				paintValue()
				push(false)
			end, current)

			return {
				Row = row,
				Set = function(v)
					if multi and type(v) == "table" then
						selectedSet = {}
						for _, x in ipairs(v) do selectedSet[x] = true end
					elseif not multi then
						selected = v
					end
					paintValue()
					push(false)
				end,
				Get = current,
				Refresh = function(newOptions)
					options = newOptions or options
					local changed = false
					if multi then
						local keep = {}
						for _, opt in ipairs(options) do
							if selectedSet[opt] then keep[opt] = true end
						end
						for opt in pairs(selectedSet) do
							if not keep[opt] then changed = true end
						end
						selectedSet = keep
					elseif selected ~= nil then
						local found = false
						for _, opt in ipairs(options) do
							if opt == selected then
								found = true
								break
							end
						end
						if not found then
							selected = options[1]
							changed = true
						end
					end
					paintValue()
					if changed then push(false) end
				end,
			}
		end

		function group.Color(o)
			o = o or {}
			local ch, cs, cv = 0, 1, 1
			local savedClr = o.flag and Vision.Flags[o.flag]
			local initClr = (typeof(savedClr) == "Color3" and savedClr) or o.default
			if typeof(initClr) == "Color3" then
				ch, cs, cv = initClr:ToHSV()
			end

			local row = baseRow(22)
			make("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Color",
				TextSize = TEXT,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			registerSearch(o.text or "Color", row)
			local swatch = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 24, 0, 14),
				BackgroundColor3 = Color3.fromHSV(ch, cs, cv),
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(swatch, 2)
			stroke(swatch, Theme.ControlBorder, 0.2)

			local function color()
				return Color3.fromHSV(ch, cs, cv)
			end

			local function push(silent)
				if o.flag then Vision.Flags[o.flag] = color(); Vision._scheduleSave() end
				if not silent and o.callback then
					task.spawn(o.callback, color())
				end
			end

			swatch.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					openHuePopup(swatch, function() return ch end, function(h)
						ch, cs, cv = h, 1, 1
						swatch.BackgroundColor3 = color()
						push(false)
					end)
				end
			end)

			push(true)
			bindFlag(o.flag, function(v)
				if typeof(v) == "Color3" then
					ch, cs, cv = v:ToHSV()
					swatch.BackgroundColor3 = color()
					push(false)
				end
			end, color)

			return {
				Row = row,
				Set = function(c)
					ch, cs, cv = c:ToHSV()
					swatch.BackgroundColor3 = color()
					push(false)
				end,
				Get = color,
			}
		end

		function group.Button(o)
			o = o or {}
			local row = baseRow(28)
			local btn = make("Frame", {
				Size = UDim2.new(1, 0, 0, 24),
				Position = UDim2.new(0, 0, 0, 2),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(btn, 3)
			local btnStroke = stroke(btn, Theme.ControlBorder, 0.3)
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_MED,
				Text = o.text or "Button",
				TextSize = 12,
				TextColor3 = Theme.TextBright,
				Parent = btn,
			})
			registerSearch(o.text or "Button", row)

			btn.MouseEnter:Connect(function()
				tween(btnStroke, { Color = Theme.Accent, Transparency = 0.2 }, 0.12)
			end)
			btn.MouseLeave:Connect(function()
				tween(btnStroke, { Color = Theme.ControlBorder, Transparency = 0.3 }, 0.15)
			end)
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					tween(lbl, { TextColor3 = Theme.Accent }, 0.06)
					task.delay(0.12, function()
						tween(lbl, { TextColor3 = Theme.TextBright }, 0.2)
					end)
					if o.callback then
						task.spawn(o.callback)
					end
				end
			end)

			return { Row = row }
		end

		function group.Textbox(o)
			o = o or {}
			local row = baseRow(26)
			if o.text then
				make("TextLabel", {
					Size = UDim2.new(1, -130, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT_MED,
					Text = o.text,
					TextSize = TEXT,
					TextColor3 = Theme.TextBright,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				registerSearch(o.text, row)
			end
			local boxW = o.text and 112 or 0
			local box = make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = o.text and UDim2.new(0, boxW, 0, 22) or UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				Parent = row,
			})
			corner(box, 3)
			local boxStroke = stroke(box, Theme.ControlBorder, 0.3)
			local input = make("TextBox", {
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = (o.flag and Vision.Flags[o.flag]) or o.default or "",
				PlaceholderText = o.placeholder or "",
				PlaceholderColor3 = Theme.TextDim,
				TextSize = 12,
				TextColor3 = Theme.TextBright,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Parent = box,
			})

			local function setText(t, silent)
				input.Text = tostring(t == nil and "" or t)
				if o.flag then Vision.Flags[o.flag] = input.Text; Vision._scheduleSave() end
				if not silent and o.callback then
					task.spawn(o.callback, input.Text, false)
				end
			end

			input.Focused:Connect(function()
				tween(boxStroke, { Color = Theme.Accent, Transparency = 0.1 }, 0.1)
			end)
			input.FocusLost:Connect(function(enter)
				tween(boxStroke, { Color = Theme.ControlBorder, Transparency = 0.3 }, 0.12)
				if o.flag then Vision.Flags[o.flag] = input.Text; Vision._scheduleSave() end
				if o.callback then
					task.spawn(o.callback, input.Text, enter)
				end
			end)

			if o.flag then Vision.Flags[o.flag] = input.Text; Vision._scheduleSave() end
			bindFlag(o.flag, function(v) setText(v, false) end, function() return input.Text end)

			return {
				Row = row,
				Set = function(t) setText(t) end,
				Get = function() return input.Text end,
			}
		end
	end

	function openHuePopup(anchor, getHue, setHue)
		openOverlay(function(root)
			local wp = win.AbsolutePosition
			local ap = anchor.AbsolutePosition
			local popW, popH = 170, 40
			local x = math.clamp(ap.X - wp.X + anchor.AbsoluteSize.X - popW, 8, WIN_W - popW - 8)
			local y = ap.Y - wp.Y + anchor.AbsoluteSize.Y + 6
			if y + popH > WIN_H - FOOTER_H then
				y = ap.Y - wp.Y - popH - 6
			end
			local pop = make("Frame", {
				Position = UDim2.new(0, x, 0, y),
				Size = UDim2.new(0, popW, 0, popH),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				ZIndex = 52,
				Parent = root,
			})
			corner(pop, 3)
			stroke(pop, Theme.ControlBorder, 0.2)

			local rail = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -20, 0, 10),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 53,
				Parent = pop,
			})
			corner(rail, 3)
			make("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = rail,
			})
			local knob = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(getHue(), 0, 0.5, 0),
				Size = UDim2.new(0, 6, 0, 14),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 54,
				Parent = rail,
			})
			corner(knob, 2)
			stroke(knob, Color3.fromRGB(20, 20, 22), 0)

			local dragging = false
			local function fromX(px)
				local a = math.clamp((px - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				setHue(a)
			end
			pop.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					fromX(input.Position.X)
				end
			end)
			local moveConn = UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					fromX(input.Position.X)
				end
			end)
			local upConn = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)
			popupCleanup = function()
				pcall(function() moveConn:Disconnect() end)
				pcall(function() upConn:Disconnect() end)
			end
		end, function()
			if popupCleanup then
				popupCleanup()
				popupCleanup = nil
			end
		end)
	end

	local searchToken = 0
	local searchOpenFlag = false

	local function flashRow(row)
		local hl = make("Frame", {
			Size = UDim2.new(1, 8, 1, 4),
			Position = UDim2.new(0, -4, 0, -2),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = row,
		})
		corner(hl, 3)
		task.spawn(function()
			for _ = 1, 2 do
				tween(hl, { BackgroundTransparency = 0.75 }, 0.16)
				task.wait(0.2)
				tween(hl, { BackgroundTransparency = 1 }, 0.22)
				task.wait(0.26)
			end
			hl:Destroy()
		end)
	end

	local function runSearch(q)
		q = string.lower(q or "")
		if q == "" then
			if searchOpenFlag then
				searchOpenFlag = false
				closeOverlay()
			end
			return
		end
		searchToken = searchToken + 1
		local myToken = searchToken
		local hits = {}
		for _, e in ipairs(searchIndex) do
			if string.find(string.lower(e.text), q, 1, true) or string.find(string.lower(e.group.Name), q, 1, true) then
				hits[#hits + 1] = e
				if #hits >= 8 then break end
			end
		end
		openOverlay(function(root)
			local listH = math.max(#hits, 1) * 26 + 8
			local list = make("Frame", {
				Position = UDim2.new(0, MARGIN + 56, 0, TOPBAR_H - 6),
				Size = UDim2.new(0, 240, 0, listH),
				BackgroundColor3 = Theme.ControlBg,
				BorderSizePixel = 0,
				ZIndex = 52,
				Parent = root,
			})
			corner(list, 3)
			stroke(list, Theme.ControlBorder, 0.2)
			make("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = list,
			})
			make("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				Parent = list,
			})
			if #hits == 0 then
				make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					Font = FONT,
					Text = "No results",
					TextSize = 12,
					TextColor3 = Theme.TextDim,
					ZIndex = 53,
					Parent = list,
				})
			end
			for i, e in ipairs(hits) do
				local item = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = i,
					ZIndex = 53,
					Parent = list,
				})
				local il = make("TextLabel", {
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT,
					Text = e.tab.Name .. "  >  " .. e.group.Name .. "  >  " .. e.text,
					TextSize = 12,
					TextColor3 = Theme.TextMid,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 53,
					Parent = item,
				})
				item.MouseEnter:Connect(function()
					tween(il, { TextColor3 = Theme.TextBright }, 0.1)
				end)
				item.MouseLeave:Connect(function()
					tween(il, { TextColor3 = Theme.TextMid }, 0.1)
				end)
				item.MouseButton1Click:Connect(function()
					searchOpenFlag = false
					searchBox.Text = ""
					closeOverlay()
					setActiveTab(e.tab)
					task.delay(0.05, function()
						local page = e.tab.Page
						local rowY = e.row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
						page.CanvasPosition = Vector2.new(0, math.max(0, rowY - 80))
						flashRow(e.row)
					end)
				end)
			end
		end, function()
			if myToken == searchToken then
				searchOpenFlag = false
			end
		end)
		searchOpenFlag = true
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		runSearch(searchBox.Text)
	end)

	local menuVisible = true
	local fadeCache = nil
	local fadeLock = 0

	local function setMenuVisible(v)
		if v == menuVisible then return end
		if os.clock() < fadeLock then return end
		fadeLock = os.clock() + 0.2
		menuVisible = v
		if not v then
			closeOverlay()
			hideTooltip()
			fadeCache = collectFade(win)
			for _, e in ipairs(fadeCache) do
				tween(e.inst, { [e.prop] = 1 }, 0.14)
			end
			task.delay(0.15, function()
				if not menuVisible then
					win.Visible = false
				end
			end)
		else
			win.Visible = true
			if fadeCache then
				for _, e in ipairs(fadeCache) do
					tween(e.inst, { [e.prop] = e.value }, 0.16)
				end
			end
		end
	end

function self.ToggleMenu()
	if isKeyLocked() then return end
	setMenuVisible(not menuVisible)
	end
function self.SetMenuVisible(v)
	if isKeyLocked() then return end
	setMenuVisible(v and true or false)
	end
	function self.SetMenuKey(kc)
		menuKey = kc
		menuKeyLbl.Text = "Menu: " .. keyName(menuKey)
	end

	-- ================================================================
	-- Theme system
	-- ================================================================

	local function repaintTheme(old)
		for _, d in ipairs(win:GetDescendants()) do
			local cn = d.ClassName
			-- UIGradient on group headers
			if cn == "UIGradient" and d.Name == "ThemeGradient" then
				d.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.GradientTop),
					ColorSequenceKeypoint.new(0.55, Theme.HeaderMid),
					ColorSequenceKeypoint.new(1, Theme.AccentDark),
				})
			-- Group head frame
			elseif d.Name == "Head" and d:IsA("Frame") then
				d.BackgroundColor3 = Theme.AccentDark
			-- Info circle (tooltip trigger)
			elseif d.Name == "InfoCircle" and d:IsA("Frame") then
				d.BackgroundColor3 = Theme.InfoBg
			-- Remap GuiObject background colors
			elseif d:IsA("GuiObject") then
				pcall(function()
					local bc = d.BackgroundColor3
					if bc == old.WindowBg then d.BackgroundColor3 = Theme.WindowBg
					elseif bc == old.PanelBg then d.BackgroundColor3 = Theme.PanelBg
					elseif bc == old.ControlBg then d.BackgroundColor3 = Theme.ControlBg
					elseif bc == old.Track then d.BackgroundColor3 = Theme.Track
					elseif bc == old.ChromeBg then d.BackgroundColor3 = Theme.ChromeBg
					end
				end)
			end
			-- UIStroke borders
			if cn == "UIStroke" then
				pcall(function()
					if d.Color == old.ControlBorder then
						d.Color = Theme.ControlBorder
					end
				end)
			end
			-- Text colors — remap old text color to matching new one
			if cn == "TextLabel" or cn == "TextBox" or cn == "TextButton" then
				pcall(function()
					local tc = d.TextColor3
					if old.oldTextWhite and tc == old.oldTextWhite then d.TextColor3 = Theme.TextWhite
					elseif old.oldTextBright and tc == old.oldTextBright then d.TextColor3 = Theme.TextBright
					elseif old.oldTextMid and tc == old.oldTextMid then d.TextColor3 = Theme.TextMid
					elseif old.oldTextDim and tc == old.oldTextDim then d.TextColor3 = Theme.TextDim
					elseif old.oldInfoText and tc == old.oldInfoText then d.TextColor3 = Theme.InfoText
					end
				end)
			end
			-- Placeholder text
			if cn == "TextBox" then
				pcall(function()
					if old.oldTextDim and d.PlaceholderColor3 == old.oldTextDim then
						d.PlaceholderColor3 = Theme.TextDim
					end
				end)
			end
			-- Scrollbar
			if cn == "ScrollingFrame" then
				pcall(function()
					if old.ControlBorder and d.ScrollBarImageColor3 == old.ControlBorder then
						d.ScrollBarImageColor3 = Theme.ControlBorder
					end
				end)
			end
		end
		-- Window background
		win.BackgroundColor3 = Theme.WindowBg
		-- Call any registered per-element repaint functions (toggles, sliders)
		for _, fn in ipairs(themeRepaints) do
			pcall(fn)
		end
	end

	function self.SetTheme(name)
		local t = Themes[name]
		if not t then return false end
		-- Snapshot old colors before overwriting Theme
		local old = {
			WindowBg = Theme.WindowBg,
			PanelBg = Theme.PanelBg,
			ControlBg = Theme.ControlBg,
			ControlBorder = Theme.ControlBorder,
			Track = Theme.Track,
			ChromeBg = Theme.ChromeBg,
			AccentDark = Theme.AccentDark,
			HeaderMid = Theme.HeaderMid,
			InfoBg = Theme.InfoBg,
			oldTextWhite = Theme.TextWhite,
			oldTextBright = Theme.TextBright,
			oldTextMid = Theme.TextMid,
			oldTextDim = Theme.TextDim,
			oldInfoText = Theme.InfoText,
		}
		for k, v in pairs(t) do
			Theme[k] = v
		end
		currentThemeName = name
		Vision.Flags["theme"] = name; Vision._scheduleSave()
		repaintTheme(old)
		return true
	end

	function self.GetTheme()
		return currentThemeName
	end

	function self.ListThemes()
		local names = {}
		for name in pairs(Themes) do
			names[#names + 1] = name
		end
		table.sort(names)
		return names
	end

	-- Apply theme from opts if given
	if opts.theme and Themes[opts.theme] then
		self.SetTheme(opts.theme)
	end

	trackConn(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or anyListening then return end
		if menuKey and input.KeyCode == menuKey then
			self.ToggleMenu()
		end
	end))

	local function encodeValue(v)
		if typeof(v) == "Color3" then
			return { __color = { v.R, v.G, v.B } }
		end
		return v
	end

	local function decodeValue(v)
		if type(v) == "table" and v.__color then
			return Color3.new(v.__color[1], v.__color[2], v.__color[3])
		end
		return v
	end

	function self.SaveConfig(cfgName)
		if not canFile() or not HttpService then return false end
		cfgName = (cfgName == nil or cfgName == "") and "default" or tostring(cfgName)
		ensureFolder()
		local out = {}
		for flag, v in pairs(Vision.Flags) do
			out[flag] = encodeValue(v)
		end
		local ok = pcall(function()
			writefile(CONFIG_FOLDER .. "/configs/" .. cfgName .. ".json", HttpService:JSONEncode(out))
		end)
		return ok
	end

	function self.LoadConfig(cfgName)
		if not canFile() or not HttpService then return false end
		cfgName = (cfgName == nil or cfgName == "") and "default" or tostring(cfgName)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/configs/" .. cfgName .. ".json"))
		end)
		if not ok or type(data) ~= "table" then return false end
		for flag, v in pairs(data) do
			local entry = flagBinds[flag]
			if entry then
				pcall(entry.set, decodeValue(v))
			else
				Vision.Flags[flag] = decodeValue(v)
			end
		end
		-- Restore theme if one was saved
		if type(Vision.Flags["theme"]) == "string" then
			self.SetTheme(Vision.Flags["theme"])
		end
		return true
	end

	function self.ListConfigs()
		local names = {}
		if type(listfiles) ~= "function" then return names end
		ensureFolder()
		pcall(function()
			for _, f in ipairs(listfiles(CONFIG_FOLDER .. "/configs")) do
				local n = string.match(f, "([^/\\]+)%.json$")
				if n then names[#names + 1] = n end
			end
		end)
		return names
	end

	--- Apply multiple flag values at once, syncing both Vision.Flags
	--- and the bound UI widgets (sliders, toggles, dropdowns, etc.).
	--- Usage: Vision.ApplyFlags({ aimbot_fov = 90, aimbot_smoothing = 5 })
	function self.ApplyFlags(dict)
		if type(dict) ~= "table" then return end
		for flag, val in pairs(dict) do
			Vision.Flags[flag] = val
			local entry = flagBinds[flag]
			if entry and entry.set then
				pcall(entry.set, val)
			end
		end
	end

	self.Flags = Vision.Flags
	self.Window = win	-- ═══════════════════════════════════════════════════════════════
	--  AUTO-SAVE / AUTO-LOAD API
	-- ═══════════════════════════════════════════════════════════════
local AUTOSAVE_FILE = CONFIG_FOLDER .. "/autosave.json"
local canAS = canFile() and HttpService ~= nil

--- Save all flags to disk
local function doSave()
	if not canAS then return end
	ensureFolder()
	local out = {}
	for flag, v in pairs(Vision.Flags) do
		out[flag] = encodeValue(v)
	end
	pcall(function() writefile(AUTOSAVE_FILE, HttpService:JSONEncode(out)) end)
end

--- Wire the API functions
_saveFunc = doSave

--- Load flags from disk and apply to widgets
function self.AutoLoad()
	if not canAS then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(AUTOSAVE_FILE))
	end)
	if not ok or type(data) ~= "table" then return false end
	for flag, v in pairs(data) do
		local entry = flagBinds[flag]
		if entry then
			pcall(entry.set, decodeValue(v))
		else
			Vision.Flags[flag] = decodeValue(v)
		end
	end
	if type(Vision.Flags["theme"]) == "string" then
		pcall(function() self.SetTheme(Vision.Flags["theme"]) end)
	end
	return true
end

--- Save on game close
pcall(function()
	game:BindToClose(function() pcall(doSave) end)
end)

--- Save instantly when local player leaves
pcall(function()
	Players.PlayerRemoving:Connect(function(plr)
		if plr == LocalPlayer then pcall(doSave) end
	end)
end)

--- Auto-load on init
pcall(function()
	if self.AutoLoad() then
		task.delay(1, function()
			self.Notify({ title = "Vision", text = "Settings restored.", type = "info", duration = 3 })
		end)
	end
end)

	return self
end

return Vision
