local LIBRARY_URL = "https://raw.githubusercontent.com/Plutana-eng-hash/Plutana-eng-hash.github.io/refs/heads/main/lua/Plutana-menu/lib.lua"
local CONFIG_FILE = "ControlPanel_config.json"

local TAG = "[Control Panel]"
local function log(...)   print(TAG, ...) end
local function warnf(...) warn(TAG, ...)  end

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function safe(label, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then warnf(("%q errored: %s"):format(label, tostring(err))) end
    end
end

local function firstOfType(t, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if typeof(v) == t then return v end
    end
end

local function parseChoice(x)
    if typeof(x) == "string" then return x end
    if typeof(x) == "table" then
        for _, k in ipairs({ "Value", "Name", "Text" }) do
            if typeof(x[k]) == "string" then return x[k] end
        end
        if typeof(x[1]) == "string" then return x[1] end
        for k, v in pairs(x) do
            if v == true and typeof(k) == "string" then return k end
        end
    end
end

local function pickString(options, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        local s = parseChoice(v)
        if s and table.find(options, s) then return s end
        if typeof(v) == "number" and options[v] then return options[v] end
    end
end

local function createLoadingScreen()
    if not LocalPlayer then return end
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder =
        "ControlPanel_Loading", false, true, 10000
    local frame = Instance.new("Frame")
    frame.Size, frame.BorderSizePixel = UDim2.fromScale(1, 1), 0
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = gui
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Text, label.Font, label.TextSize = "Loading Control Panel...", Enum.Font.GothamMedium, 22
    label.TextColor3 = Color3.fromRGB(20, 20, 20)
    label.Parent = frame
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return gui
end

local function loadLibrary(url)
    local ok, result = pcall(function()
        local src = game:HttpGet(url .. "?t=" .. os.time(), true)
        local chunk, err = loadstring(src)
        if not chunk then error("compile failed: " .. tostring(err), 0) end
        return chunk()
    end)
    if not ok then return nil, "failed to load library: " .. tostring(result) end
    if typeof(result) ~= "table" or typeof(result.CreateWindow) ~= "function" then
        return nil, "library did not return a table with CreateWindow"
    end
    return result
end

local FILL_PRESETS = {
    Red = Color3.fromRGB(255, 40, 40),   Green = Color3.fromRGB(40, 255, 40),
    Blue = Color3.fromRGB(40, 140, 255), Cyan = Color3.fromRGB(40, 255, 255),
    Magenta = Color3.fromRGB(255, 40, 255), Yellow = Color3.fromRGB(255, 255, 40),
    White = Color3.fromRGB(255, 255, 255), Orange = Color3.fromRGB(255, 140, 40),
    Purple = Color3.fromRGB(180, 80, 255),
}
local FILL_OPTIONS = { "Custom", "Red", "Green", "Blue", "Cyan", "Magenta", "Yellow",
    "White", "Orange", "Purple", "Rainbow", "Health", "Team" }
local OUTLINE_OPTIONS = { "Match", "Custom", "Red", "Green", "Blue", "Cyan", "Magenta", "White", "Black" }
local TRACER_ORIGINS = { "Bottom", "Center", "Top", "Mouse" }
local DEPTH_OPTIONS = { "AlwaysOnTop", "Occluded" }

local S = {
    enabled = false, teamCheck = true, maxDistance = 0,

    cham = false, chamFillMode = "Custom", chamOutlineMode = "Match",
    chamFill = Color3.fromRGB(255, 40, 40), chamOutline = Color3.fromRGB(255, 255, 255),
    chamFillTransparency = 0.5, chamOutlineTransparency = 0,
    chamDepth = "AlwaysOnTop", chamPulse = false,

    box = false, health = false, name = false, distance = false, tracer = false,
    boxColor = Color3.fromRGB(255, 255, 255), nameColor = Color3.fromRGB(255, 255, 255),
    distanceColor = Color3.fromRGB(210, 210, 210), tracerColor = Color3.fromRGB(255, 255, 255),
    rainbow2D = false, textSize = 14, lineThickness = 1, tracerOrigin = "Bottom",

    visibleCheck = false,

    aim = false, aimKey = "Right Mouse", aimPart = "Head", aimSmooth = 5,
    aimShowFov = true, aimFov = 150, aimFovColor = Color3.fromRGB(255, 255, 255),

    silent = false, silentKey = "Always", silentPart = "Head",
    silentShowFov = true, silentFov = 150, silentFovColor = Color3.fromRGB(255, 80, 80),

    trigger = false, triggerButton = "Right Mouse", triggerKey = "Always",
    triggerDelay = 0, triggerCooldown = 100, triggerRange = 1000,
}

local state = { drawings = {}, highlights = {}, conns = {} }

local function encodeValue(v)
    if typeof(v) == "Color3" then
        return { __c = { math.floor(v.R * 255 + .5), math.floor(v.G * 255 + .5), math.floor(v.B * 255 + .5) } }
    end
    return v
end
local function decodeValue(v)
    if typeof(v) == "table" and v.__c then return Color3.fromRGB(v.__c[1], v.__c[2], v.__c[3]) end
    return v
end
local function saveConfig()
    if typeof(writefile) ~= "function" then return false end
    local out = {}
    for k, v in pairs(S) do out[k] = encodeValue(v) end
    return pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(out))
end
local function loadConfig()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" or not isfile(CONFIG_FILE) then
        return false
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if not ok or typeof(data) ~= "table" then return false end
    for k, v in pairs(data) do
        if S[k] ~= nil and typeof(decodeValue(v)) == typeof(S[k]) then S[k] = decodeValue(v) end
    end
    return true
end

local function newDrawing(kind, props)
    local o = Drawing.new(kind)
    for k, v in pairs(props) do o[k] = v end
    o.Visible = false
    return o
end

local function createDrawings()
    if typeof(Drawing) ~= "table" and typeof(Drawing) ~= "userdata" then return end
    local ok, d = pcall(function()
        return {
            box = newDrawing("Square", { Thickness = 1, Filled = false }),
            healthBg = newDrawing("Square", { Filled = true, Color = Color3.new(0, 0, 0) }),
            healthFill = newDrawing("Square", { Filled = true }),
            name = newDrawing("Text", { Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0) }),
            distance = newDrawing("Text", { Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0) }),
            tracer = newDrawing("Line", { Thickness = 1 }),
        }
    end)
    if ok then return d end
    warnf("could not create drawings: " .. tostring(d))
end

local function hideDrawings(d)
    if d then for _, o in pairs(d) do o.Visible = false end end
end

local function removeDrawings(d)
    if not d then return end
    for _, o in pairs(d) do
        pcall(function() o.Visible = false; o:Remove() end)
    end
end

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(char, part, camera)
    local ignore = { char }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    visParams.FilterDescendantsInstances = ignore
    local origin = camera.CFrame.Position
    return Workspace:Raycast(origin, part.Position - origin, visParams) == nil
end

local function isHidden(player, hrp, camera)
    if S.teamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then return true end
    if S.visibleCheck and not isVisible(player.Character, hrp, camera) then return true end
    if S.maxDistance > 0 and (camera.CFrame.Position - hrp.Position).Magnitude > S.maxDistance then
        return true
    end
    return false
end

local function renderPlayer(player, d, camera, t)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp or humanoid.Health <= 0 or isHidden(player, hrp, camera) then
        return hideDrawings(d)
    end

    local cf, size = char:GetBoundingBox()
    local top = camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y / 2, 0)).Position)
    local bottom, onScreen = camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y / 2, 0)).Position)
    if top.Z <= 0 or bottom.Z <= 0 then return hideDrawings(d) end

    local height = math.abs(bottom.Y - top.Y)
    if height < 1 then return hideDrawings(d) end
    local width = math.clamp(height * (math.max(size.X, size.Z) / math.max(size.Y, 0.001)),
        height * 0.3, height * 0.9)
    local cx, topY = (top.X + bottom.X) / 2, math.min(top.Y, bottom.Y)
    local boxX = cx - width / 2
    local rb = S.rainbow2D and Color3.fromHSV((t * 0.5) % 1, 1, 1)

    d.box.Visible = S.box
    if S.box then
        d.box.Color, d.box.Thickness = rb or S.boxColor, S.lineThickness
        d.box.Position, d.box.Size = Vector2.new(boxX, topY), Vector2.new(width, height)
    end

    local showHealth = S.health
    d.healthBg.Visible, d.healthFill.Visible = showHealth, showHealth
    if showHealth then
        local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local x = boxX - 6
        d.healthBg.Position, d.healthBg.Size = Vector2.new(x - 1, topY - 1), Vector2.new(5, height + 2)
        local fh = height * ratio
        d.healthFill.Color = Color3.fromHSV(0.33 * ratio, 1, 1)
        d.healthFill.Position, d.healthFill.Size = Vector2.new(x, topY + height - fh), Vector2.new(3, fh)
    end

    d.name.Visible = S.name
    if S.name then
        d.name.Text, d.name.Size, d.name.Color = player.DisplayName ~= player.Name
            and ("%s (@%s)"):format(player.DisplayName, player.Name) or player.Name,
            S.textSize, rb or S.nameColor
        d.name.Position = Vector2.new(cx, topY - S.textSize - 4)
    end

    d.distance.Visible = S.distance
    if S.distance then
        d.distance.Text = ("[%d studs]"):format((camera.CFrame.Position - hrp.Position).Magnitude)
        d.distance.Size, d.distance.Color = math.max(S.textSize - 2, 8), rb or S.distanceColor
        d.distance.Position = Vector2.new(cx, topY + height + 2)
    end

    d.tracer.Visible = S.tracer
    if S.tracer then
        local vp = camera.ViewportSize
        local from = ({
            Bottom = Vector2.new(vp.X / 2, vp.Y), Center = vp / 2, Top = Vector2.new(vp.X / 2, 0),
            Mouse = game:GetService("UserInputService"):GetMouseLocation(),
        })[S.tracerOrigin] or Vector2.new(vp.X / 2, vp.Y)
        d.tracer.Color, d.tracer.Thickness = rb or S.tracerColor, S.lineThickness
        d.tracer.From, d.tracer.To = from, Vector2.new(cx, topY + height)
    end
end

local function fillColor(player, t)
    local m = S.chamFillMode
    if m == "Custom" then return S.chamFill end
    if m == "Rainbow" then return Color3.fromHSV((t * 0.5) % 1, 1, 1) end
    if m == "Health" then
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then return Color3.fromHSV(0.33 * math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1), 1, 1) end
    elseif m == "Team" then
        return player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
    end
    return FILL_PRESETS[m] or S.chamFill
end

local function outlineColor(fill)
    local m = S.chamOutlineMode
    if m == "Match" then return fill end
    if m == "Custom" then return S.chamOutline end
    if m == "Black" then return Color3.new(0, 0, 0) end
    return FILL_PRESETS[m] or Color3.new(1, 1, 1)
end

local function updateHighlights(camera, t)
    for player, h in pairs(state.highlights) do
        if not h.Parent then
            state.highlights[player] = nil
        else
            local visible = S.enabled and S.cham
            if visible then
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                visible = hum and hrp and hum.Health > 0 and not isHidden(player, hrp, camera)
            end
            if visible then
                local fill = fillColor(player, t)
                h.FillColor, h.OutlineColor = fill, outlineColor(fill)
                h.FillTransparency = S.chamPulse
                    and math.clamp(S.chamFillTransparency + (math.sin(t * 3) + 1) / 2 * 0.35, 0, 1)
                    or S.chamFillTransparency
                h.OutlineTransparency = S.chamOutlineTransparency
                h.DepthMode = Enum.HighlightDepthMode[S.chamDepth]
            end
            h.Enabled = visible and true or false
        end
    end
end

local function createHighlight(player)
    local char = player.Character
    if not char or player == LocalPlayer then return end
    local old = state.highlights[player]
    if old then pcall(old.Destroy, old) end
    local h = Instance.new("Highlight")
    h.Name, h.Adornee, h.Enabled, h.Parent = "CP_ESP_Highlight", char, false, char
    state.highlights[player] = h
end

local function setupESP()
    local conns = state.conns

    local function onAdded(player)
        if player == LocalPlayer then return end
        state.drawings[player] = state.drawings[player] or createDrawings()
        createHighlight(player)
        table.insert(conns, player.CharacterAdded:Connect(function()
            task.wait(0.1)
            createHighlight(player)
        end))
    end
    local function onRemoving(player)
        removeDrawings(state.drawings[player]); state.drawings[player] = nil
        local h = state.highlights[player]
        if h then pcall(h.Destroy, h) end
        state.highlights[player] = nil
    end

    for _, p in ipairs(Players:GetPlayers()) do onAdded(p) end
    table.insert(conns, Players.PlayerAdded:Connect(onAdded))
    table.insert(conns, Players.PlayerRemoving:Connect(onRemoving))

    table.insert(conns, RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local t = os.clock()
        updateHighlights(camera, t)
        local any2D = S.enabled and (S.box or S.health or S.name or S.distance or S.tracer)
        for player, d in pairs(state.drawings) do
            if any2D then pcall(renderPlayer, player, d, camera, t) else hideDrawings(d) end
        end
    end))

    return function()
        for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
        for _, d in pairs(state.drawings) do removeDrawings(d) end
        for _, h in pairs(state.highlights) do pcall(h.Destroy, h) end
        state.drawings, state.highlights, state.conns = {}, {}, {}
    end
end

local UIS = game:GetService("UserInputService")
local KEY_OPTIONS = { "Right Mouse", "Left Mouse", "Middle Mouse", "E", "Q", "F", "C", "X",
    "LeftShift", "LeftControl", "LeftAlt", "Always" }
local PART_OPTIONS = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }
local BUTTON_OPTIONS = { "Right Mouse", "Left Mouse" }

local silentTarget, hooksActive = nil, false

local function keyDown(name)
    if name == "Always" then return true end
    if UIS:GetFocusedTextBox() then return false end
    if name == "Right Mouse" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if name == "Left Mouse" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if name == "Middle Mouse" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton3) end
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    return (ok and kc and UIS:IsKeyDown(kc)) or false
end

local function getPart(char, name)
    return char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function getClosest(radius, partName, camera)
    local mouse = UIS:GetMouseLocation()
    local bestPlayer, bestPart, bestDist = nil, nil, radius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and getPart(char, partName)
            if hum and part and hum.Health > 0
                and not (S.teamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team) then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and (S.maxDistance == 0
                    or (camera.CFrame.Position - part.Position).Magnitude <= S.maxDistance) then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if dist < bestDist and (not S.visibleCheck or isVisible(char, part, camera)) then
                        bestPlayer, bestPart, bestDist = player, part, dist
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

local function pressButton(name)
    local down, up = mouse1press, mouse1release
    if name == "Right Mouse" then down, up = mouse2press, mouse2release end
    if typeof(down) == "function" and typeof(up) == "function" then
        down(); task.wait(0.02); up()
    elseif name ~= "Right Mouse" and typeof(mouse1click) == "function" then
        mouse1click()
    end
end

local function installSilentHooks()
    if typeof(hookmetamethod) ~= "function" or typeof(newcclosure) ~= "function" then
        warnf("silent aim unavailable: executor lacks hookmetamethod/newcclosure")
        return false
    end
    local caller = typeof(checkcaller) == "function" and checkcaller or function() return false end
    local mouse = LocalPlayer:GetMouse()

    local ok, err = pcall(function()
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if hooksActive and silentTarget and silentTarget.Parent and self == mouse and not caller() then
                if key == "Hit" then return silentTarget.CFrame end
                if key == "Target" then return silentTarget end
            end
            return oldIndex(self, key)
        end))

        if typeof(getnamecallmethod) == "function" then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if hooksActive and silentTarget and silentTarget.Parent and self == Workspace and not caller() then
                    local args = { ... }
                    if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                        args[2] = (silentTarget.Position - args[1]).Unit * args[2].Magnitude
                        return oldNamecall(self, unpack(args))
                    elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList"
                        or method == "FindPartOnRayWithWhitelist") and typeof(args[1]) == "Ray" then
                        local r = args[1]
                        args[1] = Ray.new(r.Origin, (silentTarget.Position - r.Origin).Unit * r.Direction.Magnitude)
                        return oldNamecall(self, unpack(args))
                    end
                end
                return oldNamecall(self, ...)
            end))
        end
    end)
    if not ok then warnf("silent aim hook failed: " .. tostring(err)) end
    return ok
end

local function setupAim()
    local conns = {}
    hooksActive = installSilentHooks()

    local function mkCircle()
        local ok, c = pcall(function()
            local c = Drawing.new("Circle")
            c.NumSides, c.Thickness, c.Filled, c.Visible = 64, 1, false, false
            return c
        end)
        return ok and c or nil
    end
    local aimCircle, silentCircle = mkCircle(), mkCircle()

    local trigBusy = false
    local trigParams = RaycastParams.new()

    local function drawFov(c, on, radius, col, pos)
        if not c then return end
        c.Visible = on
        if on then c.Radius, c.Color, c.Position = radius, col, pos end
    end

    table.insert(conns, RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera
        silentTarget = nil
        if not camera then return end
        local mouseLoc = UIS:GetMouseLocation()

        drawFov(aimCircle, S.aim and S.aimShowFov, S.aimFov, S.aimFovColor, mouseLoc)
        drawFov(silentCircle, S.silent and S.silentShowFov, S.silentFov, S.silentFovColor, mouseLoc)

        if S.aim and keyDown(S.aimKey) then
            local _, part = getClosest(S.aimFov, S.aimPart, camera)
            if part then
                local goal = CFrame.lookAt(camera.CFrame.Position, part.Position)
                camera.CFrame = camera.CFrame:Lerp(goal, math.clamp(1 / math.max(S.aimSmooth, 1), 0.02, 1))
            end
        end

        if S.silent and keyDown(S.silentKey) then
            local _, part = getClosest(S.silentFov, S.silentPart, camera)
            silentTarget = part
        end

        if S.trigger and not trigBusy and keyDown(S.triggerKey) then
            if S.visibleCheck then
                trigParams.FilterType = Enum.RaycastFilterType.Exclude
                trigParams.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
            else
                local chars = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then table.insert(chars, p.Character) end
                end
                trigParams.FilterType = Enum.RaycastFilterType.Include
                trigParams.FilterDescendantsInstances = chars
            end

            local ray = camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
            local hit = Workspace:Raycast(ray.Origin, ray.Direction * S.triggerRange, trigParams)
            local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
            local player = model and Players:GetPlayerFromCharacter(model)
            local hum = model and model:FindFirstChildOfClass("Humanoid")

            if player and player ~= LocalPlayer and hum and hum.Health > 0
                and not (S.teamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team) then
                trigBusy = true
                task.spawn(function()
                    if S.triggerDelay > 0 then task.wait(S.triggerDelay / 1000) end
                    pcall(pressButton, S.triggerButton)
                    task.wait(math.max(S.triggerCooldown / 1000, 0.03))
                    trigBusy = false
                end)
            end
        end
    end))

    return function()
        hooksActive, silentTarget = false, nil
        for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
        for _, c in ipairs({ aimCircle, silentCircle }) do
            if c then pcall(function() c.Visible = false; c:Remove() end) end
        end
    end, hooksActive
end

local function buildPanel(Library)
    local Window = Library:CreateWindow({
        Title = "Control Panel", Size = UDim2.fromOffset(760, 540),
        Theme = "Light", ToggleKey = Enum.KeyCode.Insert,
    })

    local function notify(text)
        for _, owner in ipairs({ Library, Window }) do
            if typeof(owner.Notify) == "function" then
                if pcall(owner.Notify, owner, { Title = "Control Panel", Content = text, Text = text, Duration = 3 }) then
                    return
                end
            end
        end
        log(text)
    end

    local controls = {}
    local function bind(tab, kind, key, opts, transform)
        opts.Default = S[key]
        opts.Callback = safe(key, function(...)
            local v = transform and transform(...) or ...
            if v ~= nil then S[key] = v end
        end)
        local method = tab["Create" .. kind]
        if typeof(method) ~= "function" then return end
        local ok, ctl = pcall(method, tab, opts)
        if ok then controls[key] = ctl end
    end

    local function toggle(tab, key, name)
        bind(tab, "Toggle", key, { Name = name }, function(v) return v == true end)
    end
    local function slider(tab, key, name, min, max, dec, suffix)
        bind(tab, "Slider", key, { Name = name, Min = min, Max = max, Decimals = dec or 0, Suffix = suffix or "" },
            function(...) return firstOfType("number", ...) end)
    end
    local function dropdown(tab, key, name, options)
        bind(tab, "Dropdown", key, { Name = name, Options = options },
            function(...) return pickString(options, ...) end)
    end

    local function color(tab, key, name)
        if typeof(tab.CreateColorPicker) == "function" then
            local ok, ctl = pcall(tab.CreateColorPicker, tab, {
                Name = name, Default = S[key], Color = S[key], Value = S[key],
                Callback = safe(name, function(...)
                    local c = firstOfType("Color3", ...)
                    if c then S[key] = c end
                end),
            })
            if ok then controls[key] = ctl; return end
        end
        tab:CreateLabel(name .. " (RGB)")
        for i, ch in ipairs({ "R", "G", "B" }) do
            tab:CreateSlider({
                Name = name .. " " .. ch, Min = 0, Max = 255, Default = math.floor(({ S[key].R, S[key].G, S[key].B })[i] * 255 + .5),
                Decimals = 0, Suffix = "",
                Callback = safe(name .. ch, function(...)
                    local v = firstOfType("number", ...)
                    if not v then return end
                    local c = S[key]
                    local rgb = { c.R * 255, c.G * 255, c.B * 255 }
                    rgb[i] = v
                    S[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                end),
            })
        end
    end

    local espTab, chamTab, visTab = Window:CreateTab("ESP"), Window:CreateTab("Chams"), Window:CreateTab("Visuals")
    local aimTab, silentTab, trigTab =
        Window:CreateTab("Aim"), Window:CreateTab("Silent Aim"), Window:CreateTab("Trigger Bot")
    local setTab = Window:CreateTab("Settings")

    espTab:CreateSection("Master")
    toggle(espTab, "enabled", "Enable ESP (Master)")
    espTab:CreateLabel("Master OFF = nothing renders. ON = only the options you enabled.")
    espTab:CreateSection("Overlays")
    toggle(espTab, "box", "Box")
    toggle(espTab, "health", "Health Bar")
    toggle(espTab, "name", "Name")
    toggle(espTab, "distance", "Distance")
    toggle(espTab, "tracer", "Tracer")
    dropdown(espTab, "tracerOrigin", "Tracer Origin", TRACER_ORIGINS)
    espTab:CreateSection("Filters")
    toggle(espTab, "teamCheck", "Team Check")
    toggle(espTab, "visibleCheck", "Visible Check (ESP, Aim, Silent Aim, Trigger)")
    slider(espTab, "maxDistance", "Max Distance (0 = unlimited)", 0, 3000, 0, " studs")

    chamTab:CreateSection("Chams")
    toggle(chamTab, "cham", "Enable Chams")
    dropdown(chamTab, "chamFillMode", "Fill Color Mode", FILL_OPTIONS)
    color(chamTab, "chamFill", "Custom Fill Color")
    dropdown(chamTab, "chamOutlineMode", "Outline Color Mode", OUTLINE_OPTIONS)
    color(chamTab, "chamOutline", "Custom Outline Color")
    slider(chamTab, "chamFillTransparency", "Fill Transparency", 0, 1, 2)
    slider(chamTab, "chamOutlineTransparency", "Outline Transparency", 0, 1, 2)
    dropdown(chamTab, "chamDepth", "Depth Mode", DEPTH_OPTIONS)
    toggle(chamTab, "chamPulse", "Pulse Effect")

    visTab:CreateSection("Colors")
    color(visTab, "boxColor", "Box Color")
    color(visTab, "nameColor", "Name Color")
    color(visTab, "distanceColor", "Distance Color")
    color(visTab, "tracerColor", "Tracer Color")
    toggle(visTab, "rainbow2D", "Rainbow (overrides colors above)")
    visTab:CreateSection("Style")
    slider(visTab, "textSize", "Text Size", 8, 28, 0)
    slider(visTab, "lineThickness", "Line Thickness", 1, 5, 0)

    aimTab:CreateSection("Camera Aim")
    toggle(aimTab, "aim", "Enable Aim")
    dropdown(aimTab, "aimKey", "Aim Button", KEY_OPTIONS)
    dropdown(aimTab, "aimPart", "Aim At", PART_OPTIONS)
    slider(aimTab, "aimSmooth", "Smoothness (1 = instant)", 1, 20, 0)
    aimTab:CreateSection("FOV")
    toggle(aimTab, "aimShowFov", "Show FOV Circle")
    slider(aimTab, "aimFov", "FOV Size", 10, 600, 0, " px")
    color(aimTab, "aimFovColor", "FOV Color")
    aimTab:CreateLabel("Moves your camera toward the closest player inside the FOV while the button is held.")

    silentTab:CreateSection("Silent Aim")
    toggle(silentTab, "silent", "Enable Silent Aim")
    dropdown(silentTab, "silentKey", "Silent Aim Button", KEY_OPTIONS)
    dropdown(silentTab, "silentPart", "Aim At", PART_OPTIONS)
    silentTab:CreateSection("FOV")
    toggle(silentTab, "silentShowFov", "Show FOV Circle")
    slider(silentTab, "silentFov", "FOV Size", 10, 600, 0, " px")
    color(silentTab, "silentFovColor", "FOV Color")
    silentTab:CreateLabel("Redirects the game's mouse/raycast hits; the camera does not move. Needs hookmetamethod support, and works only in games that read Mouse.Hit or raycast from the client.")

    trigTab:CreateSection("Trigger Bot")
    toggle(trigTab, "trigger", "Enable Trigger Bot")
    dropdown(trigTab, "triggerButton", "Fire Button", BUTTON_OPTIONS)
    dropdown(trigTab, "triggerKey", "Active While Holding", KEY_OPTIONS)
    slider(trigTab, "triggerDelay", "Delay", 0, 500, 0, " ms")
    slider(trigTab, "triggerCooldown", "Cooldown", 30, 1000, 0, " ms")
    slider(trigTab, "triggerRange", "Range", 50, 2000, 0, " studs")
    trigTab:CreateLabel("Fires when a player is under your crosshair. With Visible Check off it ignores walls.")

    setTab:CreateSection("Config")
    setTab:CreateButton({ Name = "Save Config", Callback = safe("save", function()
        notify(saveConfig() and "Config saved" or "Saving not supported by this executor")
    end) })
    setTab:CreateButton({ Name = "Load Config", Callback = safe("load", function()
        if loadConfig() then
            for key, ctl in pairs(controls) do
                if typeof(ctl) == "table" then
                    for _, m in ipairs({ "Set", "SetValue", "Update" }) do
                        if typeof(ctl[m]) == "function" then pcall(ctl[m], ctl, S[key]); break end
                    end
                end
            end
            notify("Config loaded (re-open the menu if controls look stale)")
        else
            notify("No saved config found")
        end
    end) })
    setTab:CreateSection("Window")
    setTab:CreateButton({ Name = "Show / Hide Window", Callback = safe("toggle", function()
        if typeof(Window.Toggle) == "function" then Window:Toggle()
        elseif typeof(Window.SetVisible) == "function" then Window:SetVisible(true)
        else warnf("no toggle API; use Insert") end
    end) })
    setTab:CreateButton({ Name = "Unload Control Panel", Callback = safe("unload", function()
        if _G.ControlPanel then _G.ControlPanel:Destroy() end
    end) })
    setTab:CreateLabel("Insert: show / hide the window")

    notify("Loaded. Press Insert to toggle.")
    local cleanESP = setupESP()
    local cleanAim, silentOk = setupAim()
    if not silentOk then
        silentTab:CreateLabel("Silent aim is unavailable here: executor lacks hookmetamethod / newcclosure.")
    end
    return { Window = Window, Cleanup = function() pcall(cleanESP); pcall(cleanAim) end }
end

local function LoadControlPanel()
    if _G.ControlPanel and typeof(_G.ControlPanel.Destroy) == "function" then
        pcall(_G.ControlPanel.Destroy, _G.ControlPanel)
        _G.ControlPanel = nil
    end

    loadConfig()
    local loading = createLoadingScreen()
    local Library, err = loadLibrary(LIBRARY_URL)
    if not Library then
        if loading then loading:Destroy() end
        return warnf(err)
    end

    local ok, panel = pcall(buildPanel, Library)
    if loading then loading:Destroy() end
    if not ok then return warnf("failed to build panel: " .. tostring(panel)) end

    local api = { Window = panel.Window, Settings = S }
    function api:Destroy()
        pcall(panel.Cleanup)
        if self.Window and typeof(self.Window.Destroy) == "function" then
            pcall(self.Window.Destroy, self.Window)
        end
        if _G.ControlPanel == self then _G.ControlPanel = nil end
        log("unloaded")
    end

    _G.ControlPanel = api
    log("ready, press Insert to open")
    return api
end

_G.LoadControlPanel = LoadControlPanel
LoadControlPanel()
