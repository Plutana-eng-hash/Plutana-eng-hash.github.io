local LIBRARY_URL = "https://raw.githubusercontent.com/Plutana-eng-hash/Plutana-eng-hash.github.io/refs/heads/main/lua/Plutana-menu/lib.lua"

local TAG = "[Control Panel]"
local function log(...)    print(TAG, ...)          end
local function warnf(...)  warn(TAG, ...)           end

local function safeCallback(label, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            warnf(("callback %q errored: %s"):format(label, tostring(err)))
        end
    end
end

local function createLoadingScreen()
    local player = game:GetService("Players").LocalPlayer
    if not player then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "ControlPanel_Loading"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder   = 10000

    local frame = Instance.new("Frame")
    frame.Size             = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderSizePixel  = 0
    frame.Parent           = gui

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text                   = "Loading Control Panel..."
    label.TextColor3             = Color3.fromRGB(20, 20, 20)
    label.Font                   = Enum.Font.GothamMedium
    label.TextSize               = 22
    label.Parent                 = frame

    gui.Parent = player:WaitForChild("PlayerGui")
    return gui
end

local REQUIRED_METHODS = { "CreateWindow" }

local function loadLibrary(url)
    local ok, result = pcall(function()
        local src = game:HttpGet(url .. "?t=" .. tostring(os.time()), true)
        local chunk, compileErr = loadstring(src)
        if not chunk then
            error("compile failed: " .. tostring(compileErr), 0)
        end
        return chunk()
    end)

    if not ok then
        return nil, "failed to load library: " .. tostring(result)
    end
    if typeof(result) ~= "table" then
        return nil, "library returned " .. typeof(result) .. ", expected table"
    end

    local missing = {}
    for _, name in ipairs(REQUIRED_METHODS) do
        if typeof(result[name]) ~= "function" then
            table.insert(missing, ":" .. name)
        end
    end
    if #missing > 0 then
        return nil, "library missing required methods: " .. table.concat(missing, ", ")
    end
    return result
end

local function buildPanel(Library)
    local Window = Library:CreateWindow({
        Title     = "Control Panel",
        Size      = UDim2.fromOffset(760, 520),
        Theme     = "Light",
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local MainTab     = Window:CreateTab("Main")
    local SettingsTab = Window:CreateTab("Settings")

    MainTab:CreateSection("Automation")

    local autoFarmToggle = MainTab:CreateToggle({
        Name     = "Auto-Farm",
        Default  = false,
        Callback = safeCallback("Auto-Farm", function(enabled)
            log("Auto-Farm ->", enabled)
        end),
    })

    local speedModeDropdown = MainTab:CreateDropdown({
        Name     = "Speed Mode",
        Options  = { "Slow", "Normal", "Fast", "Instant" },
        Default  = "Normal",
        Callback = safeCallback("Speed Mode", function(choice)
            log("Speed Mode ->", choice)
        end),
    })

    local walkSpeedSlider = MainTab:CreateSlider({
        Name     = "WalkSpeed",
        Min      = 8,
        Max      = 100,
        Default  = 16,
        Decimals = 0,
        Suffix   = "",
        Callback = safeCallback("WalkSpeed", function(value)
            log("WalkSpeed ->", value)
        end),
    })

    MainTab:CreateSection("Info")
    MainTab:CreateLabel("Press RightShift to show or hide this window.")

    SettingsTab:CreateSection("Diagnostics")

    SettingsTab:CreateButton({
        Name     = "Print Current Settings",
        Callback = safeCallback("Print Settings", function()
            log("Current Settings")
            log("Auto-Farm :", autoFarmToggle:Get())
            log("Speed Mode:", speedModeDropdown:Get())
            log("WalkSpeed :", walkSpeedSlider:Get())
            log("End of settings")
        end),
    })

    SettingsTab:CreateButton({
        Name     = "Reset to Defaults",
        Callback = safeCallback("Reset", function()
            autoFarmToggle:Set(false)
            speedModeDropdown:Set("Normal")
            walkSpeedSlider:Set(16)
            log("reset to defaults")
        end),
    })

    SettingsTab:CreateSection("Window")

    SettingsTab:CreateButton({
        Name     = "Show / Hide Window",
        Callback = safeCallback("Toggle Window", function()
            if typeof(Window.Toggle) == "function" then
                Window:Toggle()
            elseif typeof(Window.SetVisible) == "function" then
                Window:SetVisible(true)
            else
                warnf("this library has no toggle API, use RightShift")
            end
        end),
    })

    SettingsTab:CreateSection("Shortcuts")
    SettingsTab:CreateLabel("RightShift: show / hide the window")

    return {
        Window    = Window,
        AutoFarm  = autoFarmToggle,
        SpeedMode = speedModeDropdown,
        WalkSpeed = walkSpeedSlider,
    }
end

local function LoadControlPanel()
    if _G.ControlPanel and typeof(_G.ControlPanel.Destroy) == "function" then
        pcall(function() _G.ControlPanel:Destroy() end)
        _G.ControlPanel = nil
    end

    local loadingGui = createLoadingScreen()

    local Library, err = loadLibrary(LIBRARY_URL)
    if not Library then
        if loadingGui then loadingGui:Destroy() end
        warnf(err)
        return nil
    end

    if typeof(Library.SetTheme) ~= "function" then
        warnf("hosted lib.lua is an old version, upload the new lib.lua to get the light and dark toggle")
    end

    local ok, panel = pcall(buildPanel, Library)
    if loadingGui then loadingGui:Destroy() end
    if not ok then
        warnf("failed to build panel: " .. tostring(panel))
        return nil
    end

    local api = {
        Window    = panel.Window,
        AutoFarm  = panel.AutoFarm,
        SpeedMode = panel.SpeedMode,
        WalkSpeed = panel.WalkSpeed,
    }

    function api:Destroy()
        if self.Window and typeof(self.Window.Destroy) == "function" then
            pcall(function() self.Window:Destroy() end)
        end
        if _G.ControlPanel == self then
            _G.ControlPanel = nil
        end
        log("unloaded")
    end

    _G.ControlPanel = api
    log("ready, press RightShift to open")
    return api
end

_G.LoadControlPanel = LoadControlPanel
LoadControlPanel()
