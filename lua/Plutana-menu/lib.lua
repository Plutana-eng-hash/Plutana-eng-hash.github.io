--[[
=====================================================================================
    Modern UI Library  ·  Library.lua
=====================================================================================
    A small, self-contained, table-based UI library for Roblox.

    Design goals
      * Fully encapsulated -> nothing is written to _G or shared globals.
      * The chunk RETURNS the library table, so it can be used with:
            local Library = loadstring(game:HttpGet(RAW_URL))()
      * Modular element factories: Toggle / Dropdown / Slider / Button / Label / Section
      * Responsive: a UIScale keeps the window usable on small viewports.

    API overview
        local Library = ...
        local Window  = Library:CreateWindow({ Title = "Control Panel", Size = ..., ToggleKey = ... })
        local Tab     = Window:CreateTab("Main")
        Tab:CreateToggle({ Name, Default, Callback })
        Tab:CreateDropdown({ Name, Options, Default, Callback })
        Tab:CreateSlider({ Name, Min, Max, Default, Decimals, Suffix, Callback })
        Tab:CreateButton({ Name, Callback })
        Tab:CreateLabel("text")
        Tab:CreateSection("Section Title")
        Window:Toggle()  Window:SelectTab(tab)  Library:Destroy()
=====================================================================================
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

--=====================================================================================
-- Theme (edit these values to restyle the entire library)
--=====================================================================================
local Library = {}
local Theme = {
	Background    = Color3.fromRGB(22, 22, 28),
	Surface       = Color3.fromRGB(31, 31, 39),
	SurfaceHover  = Color3.fromRGB(40, 40, 50),
	SurfaceActive = Color3.fromRGB(48, 48, 60),
	Stroke        = Color3.fromRGB(58, 58, 72),
	Accent        = Color3.fromRGB(92, 134, 255),
	Text          = Color3.fromRGB(236, 236, 244),
	TextDim       = Color3.fromRGB(148, 148, 166),
	Font          = Enum.Font.GothamMedium,
	FontBold      = Enum.Font.GothamBold,
	Corner        = UDim.new(0, 8),
}
Library.Theme = Theme -- exposed so consumers can tweak colors before creating a window

--=====================================================================================
-- Instance helpers
--=====================================================================================
local function new(className, properties, children)
	local instance = Instance.new(className)
	local parent = nil

	if properties then
		for key, value in pairs(properties) do
			if key == "Parent" then
				parent = value -- parent last so the object never renders half-configured
			else
				instance[key] = value
			end
		end
	end

	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function applyCorner(instance, radius)
	return new("UICorner", {
		CornerRadius = radius or Theme.Corner,
		Parent = instance,
	})
end

local function applyStroke(instance, color, thickness)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = instance,
	})
end

local function applyPadding(instance, top, right, bottom, left)
	return new("UIPadding", {
		PaddingTop    = UDim.new(0, top or 0),
		PaddingRight  = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft   = UDim.new(0, left or 0),
		Parent = instance,
	})
end

local function pointInGui(guiObject, point)
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X
		and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

--=====================================================================================
-- Root GUI (ScreenGui -> Root frame -> UIScale for responsiveness)
--=====================================================================================
local function resolveParent()
	-- gethui() exists in most executors; otherwise fall back to CoreGui / PlayerGui.
	local ok, result = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
		return game:GetService("CoreGui")
	end)

	if ok and result then
		return result
	end

	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local screenGui = new("ScreenGui", {
	Name = "ModernUILibrary",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
	Parent = resolveParent(),
})

local root = new("Frame", {
	Name = "Root",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = screenGui,
})

local uiScale = new("UIScale", { Scale = 1, Parent = root })

local function updateScale()
	local viewport = root.AbsoluteSize
	if viewport.Y < 1 then
		return
	end
	-- Shrinks the UI on small screens, never enlarges past 1:1
	uiScale.Scale = math.clamp(viewport.Y / 800, 0.7, 1)
end

root:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

--=====================================================================================
-- Tab object methods
--=====================================================================================
local TabMethods = {}
TabMethods.__index = TabMethods

function TabMethods:_nextOrder()
	self.ElementCount = self.ElementCount + 1
	return self.ElementCount
end

-------------------------------------------------------------------------------------
-- Toggle
-------------------------------------------------------------------------------------
function TabMethods:CreateToggle(config)
	config = config or {}
	local name = config.Name or "Toggle"
	local callback = config.Callback

	local row = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
	applyCorner(row)
	applyStroke(row)

	new("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local switch = new("Frame", {
		Name = "Switch",
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -52, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.SurfaceActive,
		BorderSizePixel = 0,
		Parent = row,
	})
	applyCorner(switch, UDim.new(1, 0))

	local knob = new("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		Parent = switch,
	})
	applyCorner(knob, UDim.new(1, 0))

	local clickArea = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
	})

	local toggle = { Value = false }

	local function setValue(value, fireCallback)
		value = value and true or false
		toggle.Value = value

		local goalColor = value and Theme.Accent or Theme.SurfaceActive
		local goalPosition = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)

		TweenService:Create(switch, TweenInfo.new(0.15), { BackgroundColor3 = goalColor }):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), { Position = goalPosition }):Play()

		if fireCallback and callback then
			task.spawn(callback, value)
		end
	end

	function toggle:Set(value)
		setValue(value, true)
	end

	function toggle:Get()
		return toggle.Value
	end

	clickArea.MouseButton1Click:Connect(function()
		setValue(not toggle.Value, true)
	end)

	setValue(config.Default == true, false)
	return toggle
end

-------------------------------------------------------------------------------------
-- Slider
-------------------------------------------------------------------------------------
function TabMethods:CreateSlider(config)
	config = config or {}
	local name     = config.Name or "Slider"
	local min      = tonumber(config.Min) or 0
	local max      = tonumber(config.Max) or 100
	local decimals = tonumber(config.Decimals) or 0
	local suffix   = config.Suffix or ""
	local callback = config.Callback

	if max <= min then
		max = min + 1
	end

	local row = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
	applyCorner(row)
	applyStroke(row)

	new("TextLabel", {
		Size = UDim2.new(1, -110, 0, 18),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0, 90, 0, 18),
		Position = UDim2.new(1, -102, 0, 8),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	local track = new("Frame", {
		Name = "Track",
		Size = UDim2.new(1, -24, 0, 4),
		Position = UDim2.new(0, 12, 0, 38),
		BackgroundColor3 = Theme.SurfaceActive,
		BorderSizePixel = 0,
		Parent = row,
	})
	applyCorner(track, UDim.new(1, 0))

	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	applyCorner(fill, UDim.new(1, 0))

	local knob = new("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		Parent = track,
	})
	applyCorner(knob, UDim.new(1, 0))

	-- Larger invisible hitbox so the slider is easy to grab
	local hitbox = new("TextButton", {
		Size = UDim2.new(1, -24, 0, 22),
		Position = UDim2.new(0, 12, 0, 29),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
	})

	local slider = { Value = min }
	local dragging = false

	local function valueFromX(x)
		local relative = (x - hitbox.AbsolutePosition.X) / math.max(hitbox.AbsoluteSize.X, 1)
		relative = math.clamp(relative, 0, 1)
		local raw = min + (max - min) * relative
		if decimals > 0 then
			raw = tonumber(string.format("%." .. decimals .. "f", raw)) or raw
		else
			raw = math.floor(raw + 0.5)
		end
		return math.clamp(raw, min, max)
	end

	local function setValue(value, fireCallback)
		value = math.clamp(tonumber(value) or min, min, max)
		if decimals <= 0 then
			value = math.floor(value + 0.5)
		end
		slider.Value = value

		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(value) .. suffix

		if fireCallback and callback then
			task.spawn(callback, value)
		end
	end

	function slider:Set(value)
		setValue(value, true)
	end

	function slider:Get()
		return slider.Value
	end

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setValue(valueFromX(input.Position.X), true)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			setValue(valueFromX(input.Position.X), true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	setValue(config.Default or min, false)
	return slider
end

-------------------------------------------------------------------------------------
-- Dropdown (single-select, expands inline and pushes the page content down)
-------------------------------------------------------------------------------------
function TabMethods:CreateDropdown(config)
	config = config or {}
	local name     = config.Name or "Dropdown"
	local options  = config.Options or {}
	local callback = config.Callback

	local container = new("Frame", {
		Name = name .. "Dropdown",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})

	local header = new("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = container,
	})
	applyCorner(header)
	applyStroke(header)

	new("TextLabel", {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(1, -130, 1, 0),
		Position = UDim2.new(0, 90, 0, 0),
		BackgroundTransparency = 1,
		Text = "Select...",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	new("TextLabel", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -24, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text = "▾",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.FontBold,
		Parent = header,
	})

	local listHeight = math.min(#options * 28 + 8, 168)

	local list = new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		ScrollBarImageTransparency = 0.4,
		ClipsDescendants = true,
		Visible = false,
		Parent = container,
	})
	applyCorner(list, UDim.new(0, 6))
	applyStroke(list)
	applyPadding(list, 4, 4, 4, 4)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	local entries = {}

	for index, optionText in ipairs(options) do
		local optionButton = new("TextButton", {
			Name = tostring(optionText),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Theme.Surface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = list,
		})
		applyCorner(optionButton, UDim.new(0, 5))

		local optionLabel = new("TextLabel", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(optionText),
			TextColor3 = Theme.TextDim,
			TextSize = 12,
			Font = Theme.Font,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = optionButton,
		})

		table.insert(entries, {
			Text = optionText,
			Button = optionButton,
			Label = optionLabel,
		})

		optionButton.MouseEnter:Connect(function()
			if entries then
				optionButton.BackgroundColor3 = Theme.SurfaceHover
				optionButton.BackgroundTransparency = 0
			end
		end)
		optionButton.MouseLeave:Connect(function()
			local isSelected = (dropdown.Value == optionText)
			optionButton.BackgroundColor3 = isSelected and Theme.Accent or Theme.Surface
			optionButton.BackgroundTransparency = isSelected and 0 or 1
		end)
	end

	local dropdown = { Value = nil }
	local isOpen = false

	local function refreshHighlights()
		for _, entry in ipairs(entries) do
			local selected = (entry.Text == dropdown.Value)
			entry.Button.BackgroundColor3 = selected and Theme.Accent or Theme.Surface
			entry.Button.BackgroundTransparency = selected and 0 or 1
			entry.Label.TextColor3 = selected and Theme.Text or Theme.TextDim
		end
	end

	local function setOpen(open)
		isOpen = open
		list.Visible = open
		list.Size = UDim2.new(1, 0, 0, open and listHeight or 0)
		container.Size = UDim2.new(1, 0, 0, open and (40 + listHeight) or 36)
	end

	local function setValue(value, fireCallback)
		dropdown.Value = value
		valueLabel.Text = value ~= nil and tostring(value) or "Select..."
		refreshHighlights()
		if fireCallback and callback then
			task.spawn(callback, value)
		end
	end

	function dropdown:Set(value)
		setValue(value, true)
	end

	function dropdown:Get()
		return dropdown.Value
	end

	for _, entry in ipairs(entries) do
		entry.Button.MouseButton1Click:Connect(function()
			setValue(entry.Text, true)
			setOpen(false)
		end)
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	header.MouseEnter:Connect(function()
		if not isOpen then
			header.BackgroundColor3 = Theme.SurfaceHover
		end
	end)

	header.MouseLeave:Connect(function()
		header.BackgroundColor3 = Theme.Surface
	end)

	-- Close when clicking somewhere else on screen
	UserInputService.InputBegan:Connect(function(input)
		if not isOpen then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if not pointInGui(header, input.Position) and not pointInGui(list, input.Position) then
			setOpen(false)
		end
	end)

	setValue(config.Default, false)
	return dropdown
end

-------------------------------------------------------------------------------------
-- Button
-------------------------------------------------------------------------------------
function TabMethods:CreateButton(config)
	config = config or {}
	local name = config.Name or "Button"
	local callback = config.Callback

	local button = new("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
	applyCorner(button)
	applyStroke(button)

	new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		Parent = button,
	})

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Theme.SurfaceHover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Theme.Surface
	end)
	button.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)

	return button
end

-------------------------------------------------------------------------------------
-- Label / Section helpers
-------------------------------------------------------------------------------------
function TabMethods:CreateLabel(text)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = tostring(text or ""),
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
end

function TabMethods:CreateSection(text)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 2, 0, 4),
		BackgroundTransparency = 1,
		Text = string.upper(tostring(text or "Section")),
		TextColor3 = Theme.TextDim,
		TextSize = 11,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	return holder
end

--=====================================================================================
-- Window object methods
--=====================================================================================
local WindowMethods = {}
WindowMethods.__index = WindowMethods

function WindowMethods:SelectTab(tab)
	if self.ActiveTab == tab then
		return
	end

	for _, candidate in ipairs(self.Tabs) do
		local isActive = (candidate == tab)
		candidate.Page.Visible = isActive
		candidate.Label.TextColor3 = isActive and Theme.Text or Theme.TextDim
		candidate.Button.BackgroundColor3 = isActive and Theme.SurfaceActive or Theme.Surface
		candidate.Button.BackgroundTransparency = isActive and 0 or 1
	end

	self.ActiveTab = tab
end

function WindowMethods:CreateTab(name)
	name = tostring(name or "Tab")
	local index = #self.Tabs + 1

	local button = new("TextButton", {
		Name = name .. "TabButton",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = self.TabBar,
	})
	applyCorner(button, UDim.new(0, 6))

	local label = new("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.TextDim,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
	})

	local page = new("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		ScrollBarImageTransparency = 0.4,
		Visible = false,
		Parent = self.Content,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	applyPadding(page, 0, 6, 0, 0)

	local tab = setmetatable({
		Window = self,
		Name = name,
		Button = button,
		Label = label,
		Page = page,
		ElementCount = 0,
	}, TabMethods)

	table.insert(self.Tabs, tab)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			button.BackgroundColor3 = Theme.Surface
			button.BackgroundTransparency = 0.5
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			button.BackgroundTransparency = 1
		end
	end)

	if index == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function WindowMethods:Toggle()
	self.Frame.Visible = not self.Frame.Visible
end

function WindowMethods:SetVisible(visible)
	self.Frame.Visible = visible and true or false
end

--=====================================================================================
-- Library entry point
--=====================================================================================
function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Window"
	local windowSize = config.Size or UDim2.fromOffset(540, 400)

	local frame = new("Frame", {
		Name = "Window",
		Size = windowSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = root,
	})
	applyCorner(frame, UDim.new(0, 12))
	applyStroke(frame)

	-- Title bar (drag handle)
	local titleBar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar,
	})

	local closeButton = new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -34, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Text = "×",
		TextColor3 = Theme.TextDim,
		TextSize = 16,
		Font = Theme.FontBold,
		AutoButtonColor = false,
		Parent = titleBar,
	})
	applyCorner(closeButton, UDim.new(0, 6))

	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = Theme.SurfaceHover
		closeButton.TextColor3 = Theme.Text
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = Theme.Surface
		closeButton.TextColor3 = Theme.TextDim
	end)

	-- Body: left tab bar + right content area
	local body = new("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	applyPadding(body, 8, 8, 8, 8)

	local tabBar = new("Frame", {
		Name = "TabBar",
		Size = UDim2.new(0, 130, 1, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = body,
	})
	applyCorner(tabBar)
	applyPadding(tabBar, 6, 6, 6, 6)
	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})

	local content = new("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 138, 0, 0),
		Size = UDim2.new(1, -138, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	local window = setmetatable({
		Frame = frame,
		TitleBar = titleBar,
		TabBar = tabBar,
		Content = content,
		Tabs = {},
		ActiveTab = nil,
		ScreenGui = screenGui,
	}, WindowMethods)

	closeButton.MouseButton1Click:Connect(function()
		window:Toggle()
	end)

	-- Dragging
	local dragging = false
	local dragStart, startPosition

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			local scaleFactor = math.max(uiScale.Scale, 0.01)

			frame.Position = UDim2.new(
				startPosition.X.Scale, startPosition.X.Offset + delta.X / scaleFactor,
				startPosition.Y.Scale, startPosition.Y.Offset + delta.Y / scaleFactor
			)
		end
	end)

	-- Optional keyboard shortcut to show/hide the window
	if config.ToggleKey then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == config.ToggleKey then
				window:Toggle()
			end
		end)
	end

	return window
end

function Library:Destroy()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

return Library -- critical: the chunk must RETURN the table for loadstring usage
