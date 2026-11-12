local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")

--=====================================================================================
-- Theme (edit these values to restyle the entire library)
--=====================================================================================
local Library = {}
Library.Version = "2.0"

local Theme = {
	Background          = Color3.fromRGB(13, 14, 21),
	BackgroundTop       = Color3.fromRGB(23, 26, 42),
	Surface             = Color3.fromRGB(24, 26, 38),
	SurfaceTransparency = 0.12,
	SurfaceHover        = Color3.fromRGB(35, 38, 55),
	SurfaceActive       = Color3.fromRGB(45, 50, 72),
	Stroke              = Color3.fromRGB(46, 50, 72),
	StrokeHover         = Color3.fromRGB(74, 84, 120),
	Accent              = Color3.fromRGB(92, 134, 255),
	Accent2             = Color3.fromRGB(165, 112, 255),
	Success             = Color3.fromRGB(82, 214, 142),
	Warning             = Color3.fromRGB(255, 190, 80),
	Danger              = Color3.fromRGB(255, 92, 106),
	Text                = Color3.fromRGB(238, 240, 250),
	TextDim             = Color3.fromRGB(150, 154, 176),
	Font                = Enum.Font.GothamMedium,
	FontBold            = Enum.Font.GothamBold,
	Corner              = UDim.new(0, 8),
}
Library.Theme = Theme -- exposed so consumers can tweak colors before creating a window

--=====================================================================================
-- Core helpers
--=====================================================================================
local connections = {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

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

local function tween(instance, duration, properties, style, direction)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		properties
	)
	t:Play()
	return t
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

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Screen-space pointer position that matches AbsolutePosition (the ScreenGui ignores the top inset)
local function pointerPosition(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y + GuiService:GetGuiInset().Y)
	end
	return UserInputService:GetMouseLocation()
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

local guiParent = resolveParent()

-- Re-executing the script replaces the previous copy instead of stacking windows
local previous = guiParent:FindFirstChild("ModernUILibrary")
if previous then
	previous:Destroy()
end

local screenGui = new("ScreenGui", {
	Name = "ModernUILibrary",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
	Parent = guiParent,
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
	uiScale.Scale = math.clamp(viewport.Y / 760, 0.6, 1)
end

root:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

--=====================================================================================
-- Notifications
--=====================================================================================
local notifyHolder = new("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -18),
	Size = UDim2.new(0, 300, 1, -36),
	BackgroundTransparency = 1,
	ZIndex = 50,
	Parent = root,
})

new("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Parent = notifyHolder,
})

local notifyCounter = 0

function Library:Notify(config)
	if type(config) == "string" then
		config = { Content = config }
	end
	config = config or {}

	local title    = tostring(config.Title or "Notice")
	local content  = tostring(config.Content or "")
	local duration = tonumber(config.Duration) or 4
	local colors = {
		Info    = Theme.Accent,
		Success = Theme.Success,
		Warning = Theme.Warning,
		Error   = Theme.Danger,
	}
	local color = colors[config.Type or "Info"] or Theme.Accent

	notifyCounter = notifyCounter + 1

	local holder = new("Frame", {
		Name = "ToastHolder",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = notifyCounter,
		Parent = notifyHolder,
	})

	local toast = new("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 66),
		Position = UDim2.new(0, 330, 0, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = holder,
	})
	applyCorner(toast, UDim.new(0, 10))
	applyStroke(toast, Theme.Stroke)

	local bar = new("Frame", {
		Size = UDim2.new(0, 3, 1, -20),
		Position = UDim2.new(0, 8, 0, 10),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = toast,
	})
	applyCorner(bar, UDim.new(1, 0))

	new("TextLabel", {
		Size = UDim2.new(1, -34, 0, 18),
		Position = UDim2.new(0, 22, 0, 9),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = toast,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -34, 0, 26),
		Position = UDim2.new(0, 22, 0, 27),
		BackgroundTransparency = 1,
		Text = content,
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = toast,
	})

	local progress = new("Frame", {
		Size = UDim2.new(1, -24, 0, 2),
		Position = UDim2.new(0, 12, 1, -6),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = toast,
	})
	applyCorner(progress, UDim.new(1, 0))

	tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, 66) }, Enum.EasingStyle.Quint)
	tween(toast, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		tween(toast, 0.3, { Position = UDim2.new(0, 330, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.28)
		tween(holder, 0.2, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quad)
		task.wait(0.22)
		holder:Destroy()
	end)
end

--=====================================================================================
-- Snow background
--=====================================================================================
local function createSnow(parent, count, height, isActive)
	local snow = new("Frame", {
		Name = "Snow",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = parent,
	})

	local rng = Random.new()
	local flakes = {}

	for i = 1, count do
		local size = rng:NextInteger(2, 5)
		local frame = new("Frame", {
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = rng:NextNumber(0.25, 0.75),
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = snow,
		})
		applyCorner(frame, UDim.new(1, 0))

		flakes[i] = {
			Frame = frame,
			X = rng:NextNumber(),
			Y = rng:NextNumber(),
			Speed = 0.04 + size * 0.014 + rng:NextNumber(0, 0.03),
			Sway = rng:NextNumber(4, 16),
			Freq = rng:NextNumber(0.6, 1.6),
			Phase = rng:NextNumber(0, math.pi * 2),
			Drift = rng:NextNumber(-0.008, 0.008),
		}
	end

	local elapsed = 0
	local heartbeat
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not snow.Parent then
			heartbeat:Disconnect()
			return
		end
		if not isActive() then
			return
		end

		elapsed = elapsed + dt
		local wind = math.sin(elapsed * 0.25) * 0.012

		for _, flake in ipairs(flakes) do
			flake.Y = flake.Y + flake.Speed * dt
			flake.X = flake.X + (flake.Drift + wind) * dt

			if flake.Y > 1.04 then
				flake.Y = -0.04
				flake.X = rng:NextNumber()
			end
			if flake.X > 1.04 then
				flake.X = -0.04
			elseif flake.X < -0.04 then
				flake.X = 1.04
			end

			flake.Frame.Position = UDim2.new(
				flake.X, math.sin(elapsed * flake.Freq + flake.Phase) * flake.Sway,
				flake.Y, 0
			)
		end
	end)
	table.insert(connections, heartbeat)

	return snow
end

--=====================================================================================
-- Shared element helpers
--=====================================================================================
local function createRow(tab, name, height)
	local row = new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		LayoutOrder = tab:_nextOrder(),
		Parent = tab.Page,
	})
	applyCorner(row)
	local stroke = applyStroke(row)
	return row, stroke
end

local function addNameLabel(parent, text, rightReserve)
	return new("TextLabel", {
		Size = UDim2.new(1, -(rightReserve or 70), 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

local function bindHover(trigger, row, stroke)
	trigger.MouseEnter:Connect(function()
		tween(row, 0.15, { BackgroundColor3 = Theme.SurfaceHover })
		tween(stroke, 0.15, { Color = Theme.StrokeHover })
	end)
	trigger.MouseLeave:Connect(function()
		tween(row, 0.2, { BackgroundColor3 = Theme.Surface })
		tween(stroke, 0.2, { Color = Theme.Stroke })
	end)
end

-- Returns a function that spawns a ripple at the mouse position
local function addRippleLayer(button, radius)
	local layer = new("CanvasGroup", {
		Name = "Ripples",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = button,
	})
	applyCorner(layer, radius or Theme.Corner)

	return function()
		local mouse = UserInputService:GetMouseLocation()
		local pos = layer.AbsolutePosition
		local size = layer.AbsoluteSize
		local x = mouse.X - pos.X
		local y = mouse.Y - pos.Y
		if x < 0 or y < 0 or x > size.X or y > size.Y then
			x, y = size.X / 2, size.Y / 2
		end

		local scale = math.max(uiScale.Scale, 0.01)
		x, y = x / scale, y / scale
		local maxSize = (size.X / scale) * 2.2

		local ripple = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Parent = layer,
		})
		applyCorner(ripple, UDim.new(1, 0))

		tween(ripple, 0.55, {
			Size = UDim2.fromOffset(maxSize, maxSize),
			BackgroundTransparency = 1,
		})
		task.delay(0.6, function()
			ripple:Destroy()
		end)
	end
end

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
-- Section / Label / Paragraph
-------------------------------------------------------------------------------------
function TabMethods:CreateSection(text)
	local holder = new("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 4, 0, 6),
		BackgroundTransparency = 1,
		Text = string.upper(tostring(text or "Section")),
		TextColor3 = Theme.Accent,
		TextSize = 11,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local line = new("Frame", {
		Size = UDim2.new(1, -4, 0, 1),
		Position = UDim2.new(0, 2, 1, -3),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = holder,
	})
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = line,
	})

	return holder
end

function TabMethods:CreateLabel(text)
	local label = new("TextLabel", {
		Name = "Label",
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
	applyPadding(label, 2, 4, 2, 4)

	local object = { Instance = label }
	function object:Set(newText)
		label.Text = tostring(newText or "")
	end
	return object
end

function TabMethods:CreateParagraph(config)
	config = config or {}

	local card = new("Frame", {
		Name = "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
	applyCorner(card)
	applyStroke(card)
	applyPadding(card, 10, 14, 12, 14)
	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card,
	})

	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = tostring(config.Title or "Title"),
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = card,
	})

	local body = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = tostring(config.Content or ""),
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 2,
		Parent = card,
	})

	local object = {}
	function object:Set(newTitle, newContent)
		if newTitle ~= nil then
			title.Text = tostring(newTitle)
		end
		if newContent ~= nil then
			body.Text = tostring(newContent)
		end
	end
	return object
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
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})
	applyCorner(button)
	local stroke = applyStroke(button)
	local ripple = addRippleLayer(button)

	local label = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		Parent = button,
	})

	-- Small accent bar on the left that grows on hover
	local accentBar = new("Frame", {
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = button,
	})
	applyCorner(accentBar, UDim.new(1, 0))

	button.MouseEnter:Connect(function()
		tween(button, 0.15, { BackgroundColor3 = Theme.SurfaceHover })
		tween(stroke, 0.15, { Color = Theme.StrokeHover })
		tween(accentBar, 0.25, { Size = UDim2.new(0, 3, 0, 18) }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.2, { BackgroundColor3 = Theme.Surface })
		tween(stroke, 0.2, { Color = Theme.Stroke })
		tween(accentBar, 0.2, { Size = UDim2.new(0, 3, 0, 0) })
	end)
	button.MouseButton1Down:Connect(function()
		tween(label, 0.1, { TextSize = 12 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(label, 0.15, { TextSize = 13 }, Enum.EasingStyle.Back)
	end)
	button.MouseButton1Click:Connect(function()
		ripple()
		if callback then
			task.spawn(callback)
		end
	end)

	local object = { Instance = button }
	function object:SetText(text)
		label.Text = tostring(text)
	end
	return object
end

-------------------------------------------------------------------------------------
-- Toggle
-------------------------------------------------------------------------------------
function TabMethods:CreateToggle(config)
	config = config or {}
	local name = config.Name or "Toggle"
	local callback = config.Callback

	local row, stroke = createRow(self, name, 40)
	addNameLabel(row, name, 70)

	local switch = new("Frame", {
		Name = "Switch",
		Size = UDim2.fromOffset(42, 22),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.SurfaceActive,
		BorderSizePixel = 0,
		Parent = row,
	})
	applyCorner(switch, UDim.new(1, 0))
	local switchStroke = applyStroke(switch, Theme.Stroke)

	local knob = new("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 3, 0.5, 0),
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
		ZIndex = 3,
		Parent = row,
	})
	bindHover(clickArea, row, stroke)

	local toggle = { Value = false }

	local function setValue(value, fireCallback)
		value = value and true or false
		toggle.Value = value

		tween(switch, 0.2, { BackgroundColor3 = value and Theme.Accent or Theme.SurfaceActive })
		tween(switchStroke, 0.2, { Color = value and Theme.Accent or Theme.Stroke })
		tween(knob, 0.3, {
			Position = value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}, Enum.EasingStyle.Back)

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

	local row, stroke = createRow(self, name, 60)

	new("TextLabel", {
		Size = UDim2.new(1, -120, 0, 18),
		Position = UDim2.new(0, 14, 0, 9),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0, 100, 0, 18),
		Position = UDim2.new(1, -114, 0, 9),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Theme.Accent,
		TextSize = 12,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	local track = new("Frame", {
		Name = "Track",
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.new(0, 14, 0, 40),
		BackgroundColor3 = Theme.SurfaceActive,
		BorderSizePixel = 0,
		Parent = row,
	})
	applyCorner(track, UDim.new(1, 0))

	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = track,
	})
	applyCorner(fill, UDim.new(1, 0))
	new("UIGradient", {
		Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
		Parent = fill,
	})

	local knob = new("Frame", {
		Name = "Knob",
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	applyCorner(knob, UDim.new(1, 0))
	local knobStroke = applyStroke(knob, Theme.Accent, 2)

	-- Larger invisible hitbox so the slider is easy to grab
	local hitbox = new("TextButton", {
		Size = UDim2.new(1, -28, 0, 26),
		Position = UDim2.new(0, 14, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = row,
	})
	bindHover(hitbox, row, stroke)

	local slider = { Value = min }
	local dragging = false

	local function format(value)
		if decimals > 0 then
			return string.format("%." .. decimals .. "f", value)
		end
		return tostring(value)
	end

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
		tween(fill, 0.08, { Size = UDim2.new(alpha, 0, 1, 0) })
		tween(knob, 0.08, { Position = UDim2.new(alpha, 0, 0.5, 0) })
		valueLabel.Text = format(value) .. suffix

		if fireCallback and callback then
			task.spawn(callback, value)
		end
	end

	local function setDragging(state)
		dragging = state
		tween(knob, 0.15, {
			Size = state and UDim2.fromOffset(17, 17) or UDim2.fromOffset(12, 12),
		}, Enum.EasingStyle.Back)
		tween(knobStroke, 0.15, { Thickness = state and 3 or 2 })
	end

	function slider:Set(value)
		setValue(value, true)
	end

	function slider:Get()
		return slider.Value
	end

	hitbox.InputBegan:Connect(function(input)
		if isPointer(input) then
			setDragging(true)
			setValue(valueFromX(pointerPosition(input).X), true)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and isPointerMove(input) then
			setValue(valueFromX(pointerPosition(input).X), true)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if dragging and isPointer(input) then
			setDragging(false)
		end
	end)

	setValue(config.Default or min, false)
	return slider
end

-------------------------------------------------------------------------------------
-- Dropdown (single or multi select, expands inline and pushes the page content down)
-------------------------------------------------------------------------------------
function TabMethods:CreateDropdown(config)
	config = config or {}
	local name     = config.Name or "Dropdown"
	local options  = config.Options or {}
	local callback = config.Callback
	local multi    = config.Multi == true

	local HEADER_HEIGHT = 38
	local ITEM_HEIGHT   = 28
	local MAX_LIST      = 176
	local ANIM          = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local dropdown    = { Value = multi and {} or nil }
	local selectedSet = {}
	local isOpen      = false
	local entries     = {}

	local container = new("Frame", {
		Name = name .. "Dropdown",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})

	local header = new("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = container,
	})
	applyCorner(header)
	local headerStroke = applyStroke(header)

	new("TextLabel", {
		Size = UDim2.new(0.45, -14, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0.55, -42, 1, 0),
		Position = UDim2.new(0.45, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "Select...",
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	-- Chevron drawn from two rotated bars (no font glyph, so it can never render as a box)
	local chevron = new("Frame", {
		Name = "Chevron",
		Size = UDim2.fromOffset(12, 8),
		Position = UDim2.new(1, -22, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = header,
	})

	local function chevronArm(x, rotation)
		local arm = new("Frame", {
			Size = UDim2.fromOffset(8, 2),
			Position = UDim2.fromOffset(x, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rotation,
			BackgroundColor3 = Theme.TextDim,
			BorderSizePixel = 0,
			Parent = chevron,
		})
		applyCorner(arm, UDim.new(1, 0))
		return arm
	end

	local armLeft  = chevronArm(3.5, 45)
	local armRight = chevronArm(8.5, -45)

	local list = new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 4),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.StrokeHover,
		ScrollBarImageTransparency = 0.3,
		ClipsDescendants = true,
		Visible = false,
		Parent = container,
	})
	applyCorner(list, UDim.new(0, 8))
	applyStroke(list)
	applyPadding(list, 4, 4, 4, 4)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	local function isSelected(text)
		if multi then
			return selectedSet[text] == true
		end
		return dropdown.Value == text
	end

	local function getListHeight()
		local count = #options
		return math.min(count * ITEM_HEIGHT + math.max(count - 1, 0) * 2 + 8, MAX_LIST)
	end

	local function applyEntryState(entry, hovered)
		local selected = isSelected(entry.Text)
		entry.Button.BackgroundColor3 = selected and Theme.SurfaceActive or Theme.SurfaceHover
		tween(entry.Button, 0.15, {
			BackgroundTransparency = selected and 0 or (hovered and 0.35 or 1),
		})
		tween(entry.Label, 0.15, {
			TextColor3 = (selected or hovered) and Theme.Text or Theme.TextDim,
		})
		entry.Dot.Visible = selected
	end

	local function refreshHighlights()
		for _, entry in ipairs(entries) do
			applyEntryState(entry, false)
		end
	end

	local function setOpen(open)
		if isOpen == open then
			return
		end
		isOpen = open

		local listHeight = getListHeight()

		if open then
			list.Visible = true
		end

		local armColor = open and Theme.Accent or Theme.TextDim
		TweenService:Create(chevron, ANIM, { Rotation = open and 180 or 0 }):Play()
		TweenService:Create(armLeft, ANIM, { BackgroundColor3 = armColor }):Play()
		TweenService:Create(armRight, ANIM, { BackgroundColor3 = armColor }):Play()
		TweenService:Create(headerStroke, ANIM, { Color = open and Theme.Accent or Theme.Stroke }):Play()
		TweenService:Create(list, ANIM, {
			Size = UDim2.new(1, 0, 0, open and listHeight or 0),
		}):Play()
		TweenService:Create(container, ANIM, {
			Size = UDim2.new(1, 0, 0, open and (HEADER_HEIGHT + 4 + listHeight) or HEADER_HEIGHT),
		}):Play()

		if not open then
			task.delay(ANIM.Time, function()
				if not isOpen then
					list.Visible = false
				end
			end)
		end
	end

	local function updateDisplay()
		if multi then
			local picked = {}
			local names = {}
			for _, option in ipairs(options) do
				if selectedSet[option] then
					table.insert(picked, option)
					table.insert(names, tostring(option))
				end
			end
			dropdown.Value = picked
			valueLabel.Text = #names > 0 and table.concat(names, ", ") or "Select..."
			valueLabel.TextColor3 = #names > 0 and Theme.Text or Theme.TextDim
		else
			local value = dropdown.Value
			valueLabel.Text = value ~= nil and tostring(value) or "Select..."
			valueLabel.TextColor3 = value ~= nil and Theme.Text or Theme.TextDim
		end
		refreshHighlights()
	end

	local function fire()
		if callback then
			task.spawn(callback, dropdown.Value)
		end
	end

	local function setValue(value, fireCallback)
		if multi then
			table.clear(selectedSet)
			if type(value) == "table" then
				for _, v in ipairs(value) do
					selectedSet[v] = true
				end
			elseif value ~= nil then
				selectedSet[value] = true
			end
		else
			dropdown.Value = value
		end
		updateDisplay()
		if fireCallback then
			fire()
		end
	end

	local function buildOptions()
		for _, entry in ipairs(entries) do
			entry.Button:Destroy()
		end
		table.clear(entries)

		for index, optionText in ipairs(options) do
			local optionButton = new("TextButton", {
				Name = tostring(optionText),
				Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
				BackgroundColor3 = Theme.SurfaceHover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = index,
				Parent = list,
			})
			applyCorner(optionButton, UDim.new(0, 6))

			local optionLabel = new("TextLabel", {
				Size = UDim2.new(1, -36, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(optionText),
				TextColor3 = Theme.TextDim,
				TextSize = 12,
				Font = Theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = optionButton,
			})

			-- Accent dot marks the selected option(s)
			local dot = new("Frame", {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.new(1, -14, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Visible = false,
				Parent = optionButton,
			})
			applyCorner(dot, UDim.new(1, 0))

			local entry = {
				Text = optionText,
				Button = optionButton,
				Label = optionLabel,
				Dot = dot,
			}
			table.insert(entries, entry)

			optionButton.MouseEnter:Connect(function()
				applyEntryState(entry, true)
			end)
			optionButton.MouseLeave:Connect(function()
				applyEntryState(entry, false)
			end)

			optionButton.MouseButton1Click:Connect(function()
				if multi then
					if selectedSet[entry.Text] then
						selectedSet[entry.Text] = nil
					else
						selectedSet[entry.Text] = true
					end
					updateDisplay()
					fire()
				else
					setValue(entry.Text, true)
					setOpen(false)
				end
			end)
		end

		refreshHighlights()
	end

	function dropdown:Set(value)
		setValue(value, true)
	end

	function dropdown:Get()
		return dropdown.Value
	end

	function dropdown:SetOptions(newOptions)
		options = newOptions or {}
		buildOptions()

		local valid = {}
		for _, option in ipairs(options) do
			valid[option] = true
		end

		if multi then
			for key in pairs(selectedSet) do
				if not valid[key] then
					selectedSet[key] = nil
				end
			end
		elseif dropdown.Value ~= nil and not valid[dropdown.Value] then
			dropdown.Value = nil
		end
		updateDisplay()

		if isOpen then
			local listHeight = getListHeight()
			list.Size = UDim2.new(1, 0, 0, listHeight)
			container.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT + 4 + listHeight)
		end
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	header.MouseEnter:Connect(function()
		tween(header, 0.15, { BackgroundColor3 = Theme.SurfaceHover })
		if not isOpen then
			tween(headerStroke, 0.15, { Color = Theme.StrokeHover })
		end
	end)

	header.MouseLeave:Connect(function()
		tween(header, 0.2, { BackgroundColor3 = Theme.Surface })
		if not isOpen then
			tween(headerStroke, 0.2, { Color = Theme.Stroke })
		end
	end)

	-- Close when clicking somewhere else on screen
	connect(UserInputService.InputBegan, function(input)
		if not isOpen or not isPointer(input) then
			return
		end
		local point = pointerPosition(input)
		if not pointInGui(header, point) and not pointInGui(list, point) then
			setOpen(false)
		end
	end)

	buildOptions()
	setValue(config.Default, false)
	return dropdown
end

-------------------------------------------------------------------------------------
-- Textbox
-------------------------------------------------------------------------------------
function TabMethods:CreateTextbox(config)
	config = config or {}
	local name     = config.Name or "Textbox"
	local callback = config.Callback

	local row, stroke = createRow(self, name, 40)
	addNameLabel(row, name, 180)

	local boxFrame = new("Frame", {
		Size = UDim2.fromOffset(150, 26),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.SurfaceActive,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = row,
	})
	applyCorner(boxFrame, UDim.new(0, 6))
	local boxStroke = applyStroke(boxFrame, Theme.Stroke)

	local box = new("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(config.Default or ""),
		PlaceholderText = config.Placeholder or "Type here...",
		PlaceholderColor3 = Theme.TextDim,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = config.ClearOnFocus == true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = boxFrame,
	})

	bindHover(row, row, stroke)

	box.Focused:Connect(function()
		tween(boxStroke, 0.15, { Color = Theme.Accent })
	end)

	box.FocusLost:Connect(function(enterPressed)
		tween(boxStroke, 0.2, { Color = Theme.Stroke })
		if callback then
			task.spawn(callback, box.Text, enterPressed)
		end
	end)

	local textbox = {}
	function textbox:Set(text)
		box.Text = tostring(text or "")
	end
	function textbox:Get()
		return box.Text
	end
	return textbox
end

-------------------------------------------------------------------------------------
-- Keybind
-------------------------------------------------------------------------------------
function TabMethods:CreateKeybind(config)
	config = config or {}
	local name     = config.Name or "Keybind"
	local callback = config.Callback -- fired when the bound key changes
	local pressed  = config.Pressed  -- fired when the bound key is pressed

	local row, stroke = createRow(self, name, 40)
	addNameLabel(row, name, 120)

	local keyButton = new("TextButton", {
		Size = UDim2.fromOffset(86, 26),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.SurfaceActive,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	applyCorner(keyButton, UDim.new(0, 6))
	local keyStroke = applyStroke(keyButton, Theme.Stroke)

	local keyLabel = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "None",
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Theme.FontBold,
		Parent = keyButton,
	})

	bindHover(row, row, stroke)

	local keybind = { Value = config.Default }
	local listening = false

	local function render()
		keyLabel.Text = keybind.Value and keybind.Value.Name or "None"
	end

	local function setKey(key, fireCallback)
		keybind.Value = key
		render()
		if fireCallback and callback then
			task.spawn(callback, key)
		end
	end

	function keybind:Set(key)
		setKey(key, true)
	end

	function keybind:Get()
		return keybind.Value
	end

	keyButton.MouseButton1Click:Connect(function()
		listening = true
		keyLabel.Text = "..."
		tween(keyStroke, 0.15, { Color = Theme.Accent })
	end)

	connect(UserInputService.InputBegan, function(input, gameProcessed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				tween(keyStroke, 0.2, { Color = Theme.Stroke })

				if input.KeyCode == Enum.KeyCode.Escape then
					render() -- cancel
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					setKey(nil, true) -- clear
				else
					setKey(input.KeyCode, true)
				end
			end
			return
		end

		if gameProcessed then
			return
		end
		if keybind.Value and input.KeyCode == keybind.Value and pressed then
			task.spawn(pressed)
		end
	end)

	render()
	return keybind
end

-------------------------------------------------------------------------------------
-- Color picker (inline expanding panel with saturation/value box, hue bar, hex input)
-------------------------------------------------------------------------------------
function TabMethods:CreateColorPicker(config)
	config = config or {}
	local name     = config.Name or "Color"
	local callback = config.Callback

	local HEADER_HEIGHT = 38
	local PANEL_HEIGHT  = 156
	local ANIM          = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local color = config.Default or Theme.Accent
	local h, s, v = color:ToHSV()
	local picker = { Value = color }
	local isOpen = false

	local container = new("Frame", {
		Name = name .. "ColorPicker",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = self:_nextOrder(),
		Parent = self.Page,
	})

	local header = new("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = container,
	})
	applyCorner(header)
	local headerStroke = applyStroke(header)
	addNameLabel(header, name, 80)

	local swatch = new("Frame", {
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = header,
	})
	applyCorner(swatch, UDim.new(0, 6))
	applyStroke(swatch, Theme.StrokeHover)

	local panel = new("Frame", {
		Name = "Panel",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 4),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = container,
	})
	applyCorner(panel, UDim.new(0, 8))
	applyStroke(panel)

	-- Saturation / value box
	local svBox = new("TextButton", {
		Name = "SV",
		Size = UDim2.new(1, -46, 0, 100),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = panel,
	})
	applyCorner(svBox, UDim.new(0, 6))

	local whiteOverlay = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = svBox,
	})
	applyCorner(whiteOverlay, UDim.new(0, 6))
	new("UIGradient", {
		Transparency = NumberSequence.new(0, 1),
		Parent = whiteOverlay,
	})

	local blackOverlay = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = svBox,
	})
	applyCorner(blackOverlay, UDim.new(0, 6))
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new(1, 0),
		Parent = blackOverlay,
	})

	local svCursor = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(s, 0, 1 - v, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = svBox,
	})
	applyCorner(svCursor, UDim.new(1, 0))
	applyStroke(svCursor, Color3.new(1, 1, 1), 2)

	-- Hue bar
	local hueBar = new("TextButton", {
		Name = "Hue",
		Size = UDim2.new(0, 16, 0, 100),
		Position = UDim2.new(1, -26, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = panel,
	})
	applyCorner(hueBar, UDim.new(0, 6))
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,     Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1,     Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})

	local hueMarker = new("Frame", {
		Size = UDim2.new(1, 6, 0, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, h, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = hueBar,
	})
	applyCorner(hueMarker, UDim.new(1, 0))
	applyStroke(hueMarker, Color3.fromRGB(20, 20, 28), 1)

	-- Hex input
	local hexFrame = new("Frame", {
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 118),
		BackgroundColor3 = Theme.SurfaceActive,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = panel,
	})
	applyCorner(hexFrame, UDim.new(0, 6))
	local hexStroke = applyStroke(hexFrame, Theme.Stroke)

	local hexBox = new("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "#RRGGBB",
		PlaceholderColor3 = Theme.TextDim,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Theme.FontBold,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hexFrame,
	})

	local function toHex(c)
		return string.format("#%02X%02X%02X",
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5))
	end

	local function parseHex(text)
		text = tostring(text):gsub("#", ""):gsub("%s", "")
		if #text ~= 6 then
			return nil
		end
		local n = tonumber(text, 16)
		if not n then
			return nil
		end
		return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
	end

	local function apply(fireCallback)
		color = Color3.fromHSV(h, s, v)
		picker.Value = color
		swatch.BackgroundColor3 = color
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueMarker.Position = UDim2.new(0.5, 0, h, 0)
		if not hexBox:IsFocused() then
			hexBox.Text = toHex(color)
		end
		if fireCallback and callback then
			task.spawn(callback, color)
		end
	end

	local function setOpen(open)
		if isOpen == open then
			return
		end
		isOpen = open

		if open then
			panel.Visible = true
		end

		TweenService:Create(headerStroke, ANIM, { Color = open and Theme.Accent or Theme.Stroke }):Play()
		TweenService:Create(panel, ANIM, {
			Size = UDim2.new(1, 0, 0, open and PANEL_HEIGHT or 0),
		}):Play()
		TweenService:Create(container, ANIM, {
			Size = UDim2.new(1, 0, 0, open and (HEADER_HEIGHT + 4 + PANEL_HEIGHT) or HEADER_HEIGHT),
		}):Play()

		if not open then
			task.delay(ANIM.Time, function()
				if not isOpen then
					panel.Visible = false
				end
			end)
		end
	end

	-- Dragging
	local dragMode = nil

	local function updateFromPointer(input)
		local point = pointerPosition(input)
		if dragMode == "sv" then
			s = math.clamp((point.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
			v = 1 - math.clamp((point.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
		elseif dragMode == "hue" then
			h = math.clamp((point.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 0.999)
		else
			return
		end
		apply(true)
	end

	svBox.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragMode = "sv"
			updateFromPointer(input)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragMode = "hue"
			updateFromPointer(input)
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragMode and isPointerMove(input) then
			updateFromPointer(input)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if dragMode and isPointer(input) then
			dragMode = nil
		end
	end)

	hexBox.Focused:Connect(function()
		tween(hexStroke, 0.15, { Color = Theme.Accent })
	end)

	hexBox.FocusLost:Connect(function()
		tween(hexStroke, 0.2, { Color = Theme.Stroke })
		local parsed = parseHex(hexBox.Text)
		if parsed then
			h, s, v = parsed:ToHSV()
			apply(true)
		end
		hexBox.Text = toHex(color)
	end)

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	header.MouseEnter:Connect(function()
		tween(header, 0.15, { BackgroundColor3 = Theme.SurfaceHover })
		if not isOpen then
			tween(headerStroke, 0.15, { Color = Theme.StrokeHover })
		end
	end)

	header.MouseLeave:Connect(function()
		tween(header, 0.2, { BackgroundColor3 = Theme.Surface })
		if not isOpen then
			tween(headerStroke, 0.2, { Color = Theme.Stroke })
		end
	end)

	connect(UserInputService.InputBegan, function(input)
		if not isOpen or not isPointer(input) then
			return
		end
		local point = pointerPosition(input)
		if not pointInGui(header, point) and not pointInGui(panel, point) then
			setOpen(false)
		end
	end)

	function picker:Set(newColor)
		if typeof(newColor) == "Color3" then
			h, s, v = newColor:ToHSV()
			apply(true)
		end
	end

	function picker:Get()
		return picker.Value
	end

	apply(false)
	return picker
end

--=====================================================================================
-- Window object methods
--=====================================================================================
local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TAB_HEIGHT = 34
local TAB_GAP    = 4
local TAB_PAD    = 8

local function tabY(index)
	return TAB_PAD + (index - 1) * (TAB_HEIGHT + TAB_GAP)
end

function WindowMethods:SelectTab(tab)
	if self.ActiveTab == tab then
		return
	end

	local previousTab = self.ActiveTab
	self.ActiveTab = tab

	for _, candidate in ipairs(self.Tabs) do
		tween(candidate.Label, 0.2, {
			TextColor3 = (candidate == tab) and Theme.Text or Theme.TextDim,
		})
	end

	if previousTab then
		tween(previousTab.Holder, 0.12, { GroupTransparency = 1 })
		task.delay(0.12, function()
			if self.ActiveTab ~= previousTab then
				previousTab.Holder.Visible = false
			end
		end)
	end

	tab.Holder.Visible = true
	tab.Holder.GroupTransparency = 1
	tab.Holder.Position = UDim2.fromOffset(0, 14)
	tween(tab.Holder, 0.35, {
		GroupTransparency = 0,
		Position = UDim2.fromOffset(0, 0),
	}, Enum.EasingStyle.Quint)

	local y = tabY(tab.Index)
	local highlightPos = UDim2.new(0, 6, 0, y)
	local indicatorPos = UDim2.new(0, 6, 0, y + (TAB_HEIGHT - 16) / 2)

	if not previousTab then
		self.Highlight.Position = highlightPos
		self.Indicator.Position = indicatorPos
		self.Highlight.Visible = true
		self.Indicator.Visible = true
	else
		tween(self.Highlight, 0.35, { Position = highlightPos }, Enum.EasingStyle.Quint)
		tween(self.Indicator, 0.4, { Position = indicatorPos }, Enum.EasingStyle.Back)
	end
end

function WindowMethods:CreateTab(name)
	name = tostring(name or "Tab")
	local index = #self.Tabs + 1

	local button = new("TextButton", {
		Name = name .. "TabButton",
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = self.TabList,
	})

	local label = new("TextLabel", {
		Size = UDim2.new(1, -28, 1, 0),
		Position = UDim2.new(0, 18, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.TextDim,
		TextSize = 13,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	local holder = new("CanvasGroup", {
		Name = name .. "Holder",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})

	local page = new("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.StrokeHover,
		ScrollBarImageTransparency = 0.3,
		Parent = holder,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	applyPadding(page, 2, 8, 8, 2)

	local tab = setmetatable({
		Window = self,
		Name = name,
		Index = index,
		Button = button,
		Label = label,
		Holder = holder,
		Page = page,
		ElementCount = 0,
	}, TabMethods)

	table.insert(self.Tabs, tab)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			tween(label, 0.15, { TextColor3 = Theme.Text })
			tween(label, 0.2, { Position = UDim2.new(0, 22, 0, 0) })
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tween(label, 0.15, { TextColor3 = Theme.TextDim })
		end
		tween(label, 0.2, { Position = UDim2.new(0, 18, 0, 0) })
	end)

	if index == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function WindowMethods:SetVisible(visible)
	visible = visible and true or false
	if self.Visible == visible then
		return
	end
	self.Visible = visible
	self.OpenToken = self.OpenToken + 1
	local token = self.OpenToken

	if visible then
		self.Frame.Visible = true
		tween(self.Frame, 0.3, { GroupTransparency = 0 })
		tween(self.Scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		tween(self.Frame, 0.2, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(self.Scale, 0.2, { Scale = 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function()
			if self.OpenToken == token and not self.Visible then
				self.Frame.Visible = false
			end
		end)
	end
end

function WindowMethods:Toggle()
	self:SetVisible(not self.Visible)
end

function WindowMethods:SetMinimized(minimized)
	minimized = minimized and true or false
	if self.Minimized == minimized then
		return
	end
	self.Minimized = minimized

	if minimized then
		tween(self.Frame, 0.35, {
			Size = UDim2.new(self.FullSize.X.Scale, self.FullSize.X.Offset, 0, 44),
		}, Enum.EasingStyle.Quint)
		task.delay(0.36, function()
			if self.Minimized then
				self.Body.Visible = false
				self.Snow.Visible = false
			end
		end)
	else
		self.Body.Visible = true
		self.Snow.Visible = self.SnowEnabled
		tween(self.Frame, 0.4, { Size = self.FullSize }, Enum.EasingStyle.Quint)
	end
end

function WindowMethods:SetSnow(enabled)
	self.SnowEnabled = enabled and true or false
	self.Snow.Visible = self.SnowEnabled and not self.Minimized
end

function WindowMethods:Notify(config)
	Library:Notify(config)
end

--=====================================================================================
-- Library entry point
--=====================================================================================
function Library:CreateWindow(config)
	config = config or {}
	local title      = config.Title or "Window"
	local subtitle   = config.Subtitle
	local windowSize = config.Size or UDim2.fromOffset(660, 460)
	local fullHeight = windowSize.Y.Offset > 0 and windowSize.Y.Offset or 460
	local snowCount  = tonumber(config.SnowCount) or 45

	local frame = new("CanvasGroup", {
		Name = "Window",
		Size = windowSize,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, -math.floor(fullHeight / 2)),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		Parent = root,
	})
	applyCorner(frame, UDim.new(0, 14))
	new("UIGradient", {
		Color = ColorSequence.new(Theme.BackgroundTop, Theme.Background),
		Rotation = 90,
		Parent = frame,
	})
	local winScale = new("UIScale", { Scale = 0.92, Parent = frame })

	local window = setmetatable({
		Frame = frame,
		Scale = winScale,
		Tabs = {},
		ActiveTab = nil,
		ScreenGui = screenGui,
		FullSize = windowSize,
		Visible = false,
		Minimized = false,
		SnowEnabled = config.Snow ~= false,
		OpenToken = 0,
	}, WindowMethods)

	-- Snow (behind everything else)
	window.Snow = createSnow(frame, snowCount, fullHeight, function()
		return window.Visible and window.SnowEnabled and not window.Minimized
	end)
	window.Snow.Visible = window.SnowEnabled

	-- Animated gradient border (inset so the CanvasGroup never clips it)
	local borderOverlay = new("Frame", {
		Name = "Border",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = frame,
	})
	applyCorner(borderOverlay, UDim.new(0, 12))
	local borderStroke = applyStroke(borderOverlay, Color3.new(1, 1, 1), 1.5)
	local borderGradient = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Theme.Stroke),
			ColorSequenceKeypoint.new(0.35, Theme.Accent),
			ColorSequenceKeypoint.new(0.65, Theme.Accent2),
			ColorSequenceKeypoint.new(1,    Theme.Stroke),
		}),
		Parent = borderStroke,
	})
	TweenService:Create(
		borderGradient,
		TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
		{ Rotation = 360 }
	):Play()

	-- Title bar (drag handle)
	local titleBar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = frame,
	})

	local logo = new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 24, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	applyCorner(logo, UDim.new(0, 4))
	local logoGradient = new("UIGradient", {
		Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
		Parent = logo,
	})
	TweenService:Create(
		logoGradient,
		TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
		{ Rotation = 360 }
	):Play()

	new("TextLabel", {
		Size = UDim2.new(0, 220, 1, 0),
		Position = UDim2.new(0, 44, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar,
	})

	if subtitle then
		new("TextLabel", {
			Size = UDim2.new(1, -200, 1, 0),
			Position = UDim2.new(0, 160, 0, 1),
			BackgroundTransparency = 1,
			Text = tostring(subtitle),
			TextColor3 = Theme.TextDim,
			TextSize = 12,
			Font = Theme.Font,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = titleBar,
		})
	end

	-- Window buttons (icons are drawn from frames so they never depend on font glyphs)
	local function windowButton(offsetX, hoverColor)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(26, 26),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme.Surface,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = titleBar,
		})
		applyCorner(b, UDim.new(0, 7))

		local function bar(rotation)
			return new("Frame", {
				Size = UDim2.fromOffset(10, 2),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = rotation,
				BackgroundColor3 = Theme.TextDim,
				BorderSizePixel = 0,
				Parent = b,
			})
		end

		local bars = {}
		b.MouseEnter:Connect(function()
			tween(b, 0.15, { BackgroundColor3 = Theme.SurfaceHover })
			for _, x in ipairs(bars) do
				tween(x, 0.15, { BackgroundColor3 = hoverColor })
			end
		end)
		b.MouseLeave:Connect(function()
			tween(b, 0.2, { BackgroundColor3 = Theme.Surface })
			for _, x in ipairs(bars) do
				tween(x, 0.2, { BackgroundColor3 = Theme.TextDim })
			end
		end)

		return b, bar, bars
	end

	local minimizeButton, minimizeBar, minimizeBars = windowButton(-68, Theme.Accent)
	table.insert(minimizeBars, minimizeBar(0))

	local closeButton, closeBar, closeBars = windowButton(-36, Theme.Danger)
	table.insert(closeBars, closeBar(45))
	table.insert(closeBars, closeBar(-45))

	-- Animated accent line under the title bar
	local line = new("Frame", {
		Name = "TitleLine",
		Size = UDim2.new(1, -28, 0, 2),
		Position = UDim2.new(0, 14, 0, 44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = frame,
	})
	applyCorner(line, UDim.new(1, 0))
	local lineGradient = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Theme.Stroke),
			ColorSequenceKeypoint.new(0.5, Theme.Accent),
			ColorSequenceKeypoint.new(1,   Theme.Accent2),
		}),
		Offset = Vector2.new(-0.6, 0),
		Parent = line,
	})
	TweenService:Create(
		lineGradient,
		TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Offset = Vector2.new(0.6, 0) }
	):Play()

	-- Body: left tab bar + right content area (fixed height so minimizing just clips it)
	local body = new("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, 48),
		Size = UDim2.new(1, 0, 0, fullHeight - 48),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = frame,
	})
	applyPadding(body, 6, 12, 12, 12)

	local tabBar = new("Frame", {
		Name = "TabBar",
		Size = UDim2.new(0, 152, 1, 0),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = Theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Parent = body,
	})
	applyCorner(tabBar, UDim.new(0, 10))
	applyStroke(tabBar)

	local highlight = new("Frame", {
		Name = "Highlight",
		Size = UDim2.new(1, -12, 0, TAB_HEIGHT),
		BackgroundColor3 = Theme.SurfaceActive,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
		Parent = tabBar,
	})
	applyCorner(highlight, UDim.new(0, 8))
	applyStroke(highlight, Theme.StrokeHover)

	local tabList = new("Frame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -58),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = tabBar,
	})
	applyPadding(tabList, TAB_PAD, 6, 0, 6)
	new("UIListLayout", {
		Padding = UDim.new(0, TAB_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList,
	})

	local indicator = new("Frame", {
		Name = "Indicator",
		Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 3,
		Parent = tabBar,
	})
	applyCorner(indicator, UDim.new(1, 0))

	-- Footer card with the local player's name
	local footer = new("Frame", {
		Size = UDim2.new(1, -12, 0, 40),
		Position = UDim2.new(0, 6, 1, -46),
		BackgroundColor3 = Theme.SurfaceActive,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = tabBar,
	})
	applyCorner(footer, UDim.new(0, 8))

	local statusDot = new("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Success,
		BorderSizePixel = 0,
		Parent = footer,
	})
	applyCorner(statusDot, UDim.new(1, 0))
	TweenService:Create(
		statusDot,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundTransparency = 0.6 }
	):Play()

	local localPlayer = Players.LocalPlayer
	new("TextLabel", {
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.new(0, 28, 0, 0),
		BackgroundTransparency = 1,
		Text = localPlayer and localPlayer.DisplayName or "Player",
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = footer,
	})

	local content = new("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 164, 0, 0),
		Size = UDim2.new(1, -164, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	window.TitleBar  = titleBar
	window.Body      = body
	window.TabBar    = tabBar
	window.TabList   = tabList
	window.Content   = content
	window.Highlight = highlight
	window.Indicator = indicator

	closeButton.MouseButton1Click:Connect(function()
		window:SetVisible(false)
	end)

	minimizeButton.MouseButton1Click:Connect(function()
		window:SetMinimized(not window.Minimized)
	end)

	-- Dragging
	local dragging = false
	local dragStart, startPosition

	titleBar.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			dragStart = pointerPosition(input)
			startPosition = frame.Position
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not dragging or not isPointerMove(input) then
			return
		end
		local delta = pointerPosition(input) - dragStart
		local scaleFactor = math.max(uiScale.Scale, 0.01)

		frame.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X / scaleFactor,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y / scaleFactor
		)
	end)

	connect(UserInputService.InputEnded, function(input)
		if dragging and isPointer(input) then
			dragging = false
		end
	end)

	-- Optional keyboard shortcut to show/hide the window
	if config.ToggleKey then
		connect(UserInputService.InputBegan, function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == config.ToggleKey then
				window:Toggle()
			end
		end)
	end

	-- Floating open button for touch-only devices (no keyboard to toggle with)
	if config.MobileButton ~= false
		and UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled then
		local mobileButton = new("TextButton", {
			Name = "MobileToggle",
			Size = UDim2.fromOffset(46, 46),
			Position = UDim2.new(0, 16, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Text = "UI",
			TextColor3 = Theme.Text,
			TextSize = 14,
			Font = Theme.FontBold,
			AutoButtonColor = false,
			ZIndex = 30,
			Parent = root,
		})
		applyCorner(mobileButton, UDim.new(1, 0))
		new("UIGradient", {
			Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
			Rotation = 45,
			Parent = mobileButton,
		})
		mobileButton.MouseButton1Click:Connect(function()
			window:Toggle()
		end)
	end

	window:SetVisible(true)
	return window
end

function Library:Destroy()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)

	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

return Library
