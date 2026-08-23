local Vision = {}
Vision.Flags = {}
Vision.Version = "1.0.0"

local Runtime = (type(getgenv) == "function" and getgenv()) or _G
local ACTIVE_WINDOW_KEY = "__VISION_ACTIVE_WINDOW_V1"function Vision.Unload()
	local active = Runtime[ACTIVE_WINDOW_KEY]
	if type(active) == "table" and type(active.Destroy) == "function" then
		pcall(active.Destroy)
	end
	Runtime[ACTIVE_WINDOW_KEY] = nil
	for flag in pairs(Vision.Flags) do

        Vision.Flags[flag] = nil
    end
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

local function destroyExistingVisionGuis()
	local parent = getGuiParent()
	if not parent then return end
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
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif type(protectgui) == "function" then
			protectgui(gui)
		end
	end)
end

local ICON_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
local iconMap = nil

local function loadIconMap()
	if iconMap ~= nil then
		return iconMap
	end
	iconMap = false
	if type(loadstring) == "function" then
		pcall(function()
			local src = game:HttpGet(ICON_URL)
			local fn = loadstring(src)
			if type(fn) == "function" then
				local ok, map = pcall(fn)
				if ok and type(map) == "table" then
					iconMap = map
				end
			end
		end)
	end
	return iconMap
end

local function resolveIcon(icon)
	if not icon or icon == 0 or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		return { Image = "rbxassetid://" .. icon }
	end
	if type(icon) == "string" then
		if string.match(icon, "^%d+$") then
			return { Image = "rbxassetid://" .. icon }
		end
		if string.find(icon, "rbxassetid://") == 1 or string.sub(icon, 1, 4) == "http" then
			return { Image = icon }
		end
		local map = loadIconMap()
		if type(map) == "table" then
			local sized = map["48px"] or map
			local entry = sized and sized[string.lower(icon)]
			if entry then
				return {
					Image = "rbxassetid://" .. entry[1],
					ImageRectSize = Vector2.new(entry[2][1], entry[2][2]),
					ImageRectOffset = Vector2.new(entry[3][1], entry[3][2]),
				}
			end
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

local ASSET_BASE = "https://raw.githubusercontent.com/SyncUnofficial/Vision/main/assets/"

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

local STRIPES_FILE = "tempus_stripes_v1.png"
local TICK_FILE = "tempus_tick_v1.png"
local LOGO_FILE = "tempus_logo_v2.png"

local Theme = {
	Accent = Color3.fromRGB(236, 110, 180),
	AccentDark = Color3.fromRGB(110, 24, 63),
	HeaderFade = Color3.fromRGB(26, 20, 24),
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
}

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
	Vision.Unload()
	destroyExistingVisionGuis()
	local self = {}
	local title = opts.title or "VISION"
	if opts.accent then
		Theme.Accent = opts.accent
	end
	local menuKey = opts.keybind or Enum.KeyCode.KeypadZero

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

	local conns = {}
	local function trackConn(c)
		conns[#conns + 1] = c
		return c
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
		if popupCleanup then
			pcall(popupCleanup)
			popupCleanup = nil
		end
		if Runtime[ACTIVE_WINDOW_KEY] == self then
			Runtime[ACTIVE_WINDOW_KEY] = nil
		end
		if screen and screen.Parent then
			screen:Destroy()
		end
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
	stroke(win, Color3.fromRGB(34, 32, 36), 0.4)

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
		BackgroundColor3 = Color3.fromRGB(30, 29, 32),
		BorderSizePixel = 0,
		Parent = win,
	})

	local logo = make("ImageLabel", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 2, 0.5, 0),
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.Accent,
		ScaleType = Enum.ScaleType.Fit,
		Parent = topbar,
	})
	local logoAsset = remoteImage(LOGO_FILE)
	if opts.logo then
		applyIcon(logo, resolveIcon(opts.logo))
	elseif logoAsset then
		logo.Image = logoAsset
	else
		applyIcon(logo, resolveIcon("hourglass"))
	end

	make("Frame", {
		Name = "LogoDivider",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 44, 0.5, 0),
		Size = UDim2.new(0, 1, 0, 30),
		BackgroundColor3 = Color3.fromRGB(34, 32, 36),
		BorderSizePixel = 0,
		Parent = topbar,
	})

	local searchIcon = make("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, MARGIN + 58, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.TextDim,
		ScaleType = Enum.ScaleType.Fit,
		Parent = topbar,
	})
	applyIcon(searchIcon, resolveIcon("search"))

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
		Position = UDim2.new(0, MARGIN, 0, 0),
		Size = UDim2.new(1, -MARGIN * 2, 0, 1),
		BackgroundColor3 = Theme.ControlBorder,
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
		local function grab(inst)
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
		return list
	end

	local tabs = {}
	local activeTab = nil
	local navX = MARGIN + 78 + 110
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

	local function setActiveTab(t)
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
			old.Page.Visible = false
			tween(old.Nav, { TextColor3 = Theme.TextDim }, 0.14)
		end
		activeTab = t
		tween(t.Nav, { TextColor3 = Theme.TextWhite }, 0.14)

		restorePage(t)
		local cache = collectFade(t.Page)
		t.LastCache = cache
		t.ActiveTweens = {}
		for _, e in ipairs(cache) do
			e.inst[e.prop] = 1
		end
		t.Page.Position = UDim2.new(0, dir * 26, 0, 0)
		t.Page.Visible = true
		t.ActiveTweens[#t.ActiveTweens + 1] = tween(t.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)

		local byGroup = {}
		for _, e in ipairs(cache) do
			local box
			for _, gr in ipairs(t.Groups) do
				if e.inst == gr.Box or e.inst:IsDescendantOf(gr.Box) then
					box = gr.Box
					break
				end
			end
			byGroup[box or t.Page] = byGroup[box or t.Page] or {}
			table.insert(byGroup[box or t.Page], e)
		end
		for gi, gr in ipairs(t.Groups) do
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
		task.delay(0.02 + #t.Groups * 0.03 + 0.24, function()
			if switchGen == gen then
				t.ActiveTweens = nil
				t.LastCache = nil
			end
		end)
	end

	function self.Tab(name, topts)
		topts = topts or {}
		local tab = {}
		tab.Name = name

		local nav = make("TextButton", {
			Name = "Nav_" .. name,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, navX, 0.5, 0),
			Size = UDim2.new(0, math.max(44, #name * 7 + 24), 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = name,
			Font = FONT_MED,
			TextSize = TEXT,
			TextColor3 = Theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			AutoButtonColor = false,
			Parent = topbar,
		})
		navX = navX + math.max(44, #name * 7 + 24) + 18

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
				tween(nav, { TextColor3 = Theme.TextBright }, 0.1)
			end
		end)
		nav.MouseLeave:Connect(function()
			if activeTab ~= tab then
				tween(nav, { TextColor3 = Theme.TextDim }, 0.1)
			end
		end)

		function tab.Group(gname, gopts)
			gopts = gopts or {}
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
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.55, Color3.new(0.45, 0.35, 0.4)),
					ColorSequenceKeypoint.new(1, Color3.new(0.22, 0.18, 0.2)),
				}),
				Parent = head,
			})
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
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 15, 0, 15),
					BackgroundColor3 = Theme.TextWhite,
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = head,
				})
				corner(infoCircle, 8)
				make("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Font = FONT_BOLD,
					Text = "!",
					TextSize = 11,
					TextColor3 = Color3.fromRGB(15, 15, 15),
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
		if not activeTab then
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
			local state = o.default and true or false
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
			local check = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 11, 0, 11),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.Check,
				ImageTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = boxBtn,
			})
			applyIcon(check, resolveIcon("check"))

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

			local function currentColor()
				return Color3.fromHSV(ch, cs, cv)
			end

			local function push(silent)
				if o.flag then Vision.Flags[o.flag] = state end
				if hasColor and o.colorFlag then Vision.Flags[o.colorFlag] = currentColor() end
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
							if o.colorFlag then Vision.Flags[o.colorFlag] = currentColor() end
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
			local key = o.default
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
				if o.flag then Vision.Flags[o.flag] = key and key.Name or "None" end
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
					if o.flag then Vision.Flags[o.flag] = key and key.Name or "None" end
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

			if o.flag then Vision.Flags[o.flag] = key and key.Name or "None" end
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
			local value = math.clamp(o.default or min, min, max)

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
				fill.Size = UDim2.new(alpha, 0, 1, 0)
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
				if o.flag then Vision.Flags[o.flag] = value end
				if not silent and o.callback then
					task.spawn(o.callback, value)
				end
			end

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
			if o.flag then Vision.Flags[o.flag] = value end
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
			if multi then
				for _, v in ipairs(o.default or {}) do
					selectedSet[v] = true
				end
			else
				selected = o.default or options[1]
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
				ImageColor3 = Theme.TextMid,
				ScaleType = Enum.ScaleType.Fit,
				Parent = chevBtn,
			})
			applyIcon(chev, resolveIcon("chevron-down"))

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
				if o.flag then Vision.Flags[o.flag] = current() end
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
			if typeof(o.default) == "Color3" then
				ch, cs, cv = o.default:ToHSV()
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
				if o.flag then Vision.Flags[o.flag] = color() end
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
				Text = o.default or "",
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
				if o.flag then Vision.Flags[o.flag] = input.Text end
				if not silent and o.callback then
					task.spawn(o.callback, input.Text, false)
				end
			end

			input.Focused:Connect(function()
				tween(boxStroke, { Color = Theme.Accent, Transparency = 0.1 }, 0.1)
			end)
			input.FocusLost:Connect(function(enter)
				tween(boxStroke, { Color = Theme.ControlBorder, Transparency = 0.3 }, 0.12)
				if o.flag then Vision.Flags[o.flag] = input.Text end
				if o.callback then
					task.spawn(o.callback, input.Text, enter)
				end
			end)

			if o.flag then Vision.Flags[o.flag] = input.Text end
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
		setMenuVisible(not menuVisible)
	end
	function self.SetMenuVisible(v)
		setMenuVisible(v and true or false)
	end
	function self.SetMenuKey(kc)
		menuKey = kc
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

	Runtime[ACTIVE_WINDOW_KEY] = self
	self.Flags = Vision.Flags
	self.Window = win
	self.Title = title
	self.Theme = Theme

	return self
end

return Vision
