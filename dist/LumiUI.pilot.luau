-- Lumi UI v0.3 Visual Pilot
-- Dense desktop-style redesign for Potassium.
-- Standalone, no game-specific logic, safe to re-execute.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ROOT_NAME = "LumiUIPilot_v01"

local Theme = {
    Backdrop = Color3.fromRGB(11, 11, 12),
    Shell = Color3.fromRGB(20, 19, 18),
    Sidebar = Color3.fromRGB(24, 23, 21),
    Surface = Color3.fromRGB(29, 28, 26),
    Surface2 = Color3.fromRGB(34, 33, 30),
    Surface3 = Color3.fromRGB(40, 38, 35),
    Stroke = Color3.fromRGB(64, 60, 53),
    StrokeSoft = Color3.fromRGB(48, 46, 42),
    Text = Color3.fromRGB(244, 240, 230),
    TextSoft = Color3.fromRGB(205, 198, 184),
    Muted = Color3.fromRGB(139, 133, 121),
    Muted2 = Color3.fromRGB(102, 98, 91),
    Accent = Color3.fromRGB(255, 235, 163),
    AccentSoft = Color3.fromRGB(121, 106, 63),
    AccentWash = Color3.fromRGB(55, 49, 34),
    Green = Color3.fromRGB(159, 214, 171),
    Red = Color3.fromRGB(226, 145, 145),
}

local function new(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    return object
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency == nil and 0 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, l, r, t, b)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent = parent,
    })
end

local function list(parent, gap)
    return new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, gap or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)
        if not ok then
            warn("[Lumi UI] callback error:", err)
        end
    end)
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    return CoreGui
end

local guiParent = getGuiParent()
local previous = guiParent:FindFirstChild(ROOT_NAME)
if previous then previous:Destroy() end

local Lumi = {_windows = {}}
Lumi.__index = Lumi

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function Lumi:Destroy()
    for _, window in ipairs(self._windows) do
        if window and window.Destroy then window:Destroy() end
    end
    table.clear(self._windows)
end

local function makeMiniIcon(parent, kind, active)
    local box = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = active and Theme.AccentWash or Theme.Surface2,
        BackgroundTransparency = active and 0 or 0.18,
        BorderSizePixel = 0,
        Parent = parent,
    })
    corner(box, 5)
    stroke(box, active and Theme.AccentSoft or Theme.StrokeSoft, active and 0.25 or 0.55, 1)

    if kind == "home" then
        new("Frame", {
            Size = UDim2.fromOffset(7, 7),
            Position = UDim2.fromOffset(5, 6),
            BackgroundColor3 = active and Theme.Accent or Theme.Muted,
            BorderSizePixel = 0,
            Parent = box,
        })
        local roof = new("Frame", {
            Size = UDim2.fromOffset(8, 2),
            Position = UDim2.fromOffset(5, 4),
            Rotation = -35,
            BackgroundColor3 = active and Theme.Accent or Theme.Muted,
            BorderSizePixel = 0,
            Parent = box,
        })
        corner(roof, 2)
    elseif kind == "player" then
        local head = new("Frame", {
            Size = UDim2.fromOffset(5, 5),
            Position = UDim2.fromOffset(6, 3),
            BackgroundColor3 = active and Theme.Accent or Theme.Muted,
            BorderSizePixel = 0,
            Parent = box,
        })
        corner(head, 5)
        local body = new("Frame", {
            Size = UDim2.fromOffset(9, 5),
            Position = UDim2.fromOffset(4, 10),
            BackgroundColor3 = active and Theme.Accent or Theme.Muted,
            BorderSizePixel = 0,
            Parent = box,
        })
        corner(body, 5)
    else
        for i = 0, 1 do
            new("Frame", {
                Size = UDim2.fromOffset(4, 4),
                Position = UDim2.fromOffset(4 + i * 6, 4),
                BackgroundColor3 = active and Theme.Accent or Theme.Muted,
                BorderSizePixel = 0,
                Parent = box,
            })
            new("Frame", {
                Size = UDim2.fromOffset(4, 4),
                Position = UDim2.fromOffset(4 + i * 6, 10),
                BackgroundColor3 = active and Theme.Accent or Theme.Muted,
                BorderSizePixel = 0,
                Parent = box,
            })
        end
    end

    return box
end

local function makeChevron(parent, x, y, color)
    local a = new("Frame", {
        Size = UDim2.fromOffset(6, 1),
        Position = UDim2.fromOffset(x, y),
        Rotation = 45,
        BackgroundColor3 = color or Theme.Muted,
        BorderSizePixel = 0,
        Parent = parent,
    })
    local b = new("Frame", {
        Size = UDim2.fromOffset(6, 1),
        Position = UDim2.fromOffset(x, y + 4),
        Rotation = -45,
        BackgroundColor3 = color or Theme.Muted,
        BorderSizePixel = 0,
        Parent = parent,
    })
    return a, b
end

function Lumi:CreateWindow(options)
    options = options or {}

    local root = new("ScreenGui", {
        Name = ROOT_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = guiParent,
    })

    local shadow = new("Frame", {
        Name = "Shadow",
        Size = UDim2.fromOffset(958, 548),
        Position = UDim2.new(0.5, -474, 0.5, -264),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.48,
        BorderSizePixel = 0,
        Parent = root,
    })
    corner(shadow, 18)

    local main = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(950, 540),
        Position = UDim2.new(0.5, -475, 0.5, -270),
        BackgroundColor3 = Theme.Shell,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    corner(main, 16)
    stroke(main, Theme.Stroke, 0.28, 1)

    local topbar = new("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })

    new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.StrokeSoft,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Parent = topbar,
    })

    local brandMark = new("Frame", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(14, 9),
        BackgroundColor3 = Theme.AccentWash,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    corner(brandMark, 8)
    stroke(brandMark, Theme.AccentSoft, 0.18, 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "L",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        Parent = brandMark,
    })

    new("TextLabel", {
        Size = UDim2.fromOffset(130, 18),
        Position = UDim2.fromOffset(49, 6),
        BackgroundTransparency = 1,
        Text = string.lower(options.Title or "lumi"),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })

    new("TextLabel", {
        Size = UDim2.fromOffset(170, 12),
        Position = UDim2.fromOffset(49, 23),
        BackgroundTransparency = 1,
        Text = "interface laboratory",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })

    local closeButton = new("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -38, 0.5, -15),
        BackgroundColor3 = Theme.Surface,
        AutoButtonColor = false,
        Text = "",
        Parent = topbar,
    })
    corner(closeButton, 8)
    stroke(closeButton, Theme.StrokeSoft, 0.5, 1)

    local closeA = new("Frame", {
        Size = UDim2.fromOffset(8, 1),
        Position = UDim2.fromOffset(11, 14),
        Rotation = 45,
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Parent = closeButton,
    })
    local closeB = new("Frame", {
        Size = UDim2.fromOffset(8, 1),
        Position = UDim2.fromOffset(11, 14),
        Rotation = -45,
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Parent = closeButton,
    })

    closeButton.MouseEnter:Connect(function()
        tween(closeButton, 0.12, {BackgroundColor3 = Color3.fromRGB(51, 31, 31)})
        tween(closeA, 0.12, {BackgroundColor3 = Theme.Red})
        tween(closeB, 0.12, {BackgroundColor3 = Theme.Red})
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, 0.12, {BackgroundColor3 = Theme.Surface})
        tween(closeA, 0.12, {BackgroundColor3 = Theme.Muted})
        tween(closeB, 0.12, {BackgroundColor3 = Theme.Muted})
    end)

    local body = new("Frame", {
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.fromOffset(0, 44),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 168, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
    })

    new("Frame", {
        Size = UDim2.fromOffset(1, 496),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.StrokeSoft,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Text = "WORKSPACE",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })

    local nav = new("Frame", {
        Name = "Navigation",
        Size = UDim2.new(1, -16, 0, 170),
        Position = UDim2.fromOffset(8, 38),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    list(nav, 4)

    local profileCard = new("Frame", {
        Size = UDim2.new(1, -16, 0, 58),
        Position = UDim2.new(0, 8, 1, -70),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    corner(profileCard, 10)
    stroke(profileCard, Theme.StrokeSoft, 0.4, 1)

    local statusDot = new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.fromOffset(12, 13),
        BackgroundColor3 = Theme.Green,
        BorderSizePixel = 0,
        Parent = profileCard,
    })
    corner(statusDot, 6)

    new("TextLabel", {
        Size = UDim2.new(1, -34, 0, 14),
        Position = UDim2.fromOffset(25, 8),
        BackgroundTransparency = 1,
        Text = "Potassium",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = profileCard,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(12, 31),
        BackgroundTransparency = 1,
        Text = "Lumi UI / visual pilot",
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = profileCard,
    })

    local workspace = new("Frame", {
        Name = "Workspace",
        Size = UDim2.new(1, -382, 1, 0),
        Position = UDim2.fromOffset(168, 0),
        BackgroundColor3 = Theme.Backdrop,
        BorderSizePixel = 0,
        Parent = body,
    })

    local inspector = new("Frame", {
        Name = "Inspector",
        Size = UDim2.new(0, 214, 1, 0),
        Position = UDim2.new(1, -214, 0, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
    })

    new("Frame", {
        Size = UDim2.fromOffset(1, 496),
        BackgroundColor3 = Theme.StrokeSoft,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = inspector,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Text = "INSPECTOR",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = inspector,
    })

    local inspectorTitle = new("TextLabel", {
        Size = UDim2.new(1, -28, 0, 22),
        Position = UDim2.fromOffset(14, 42),
        BackgroundTransparency = 1,
        Text = "Home",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = inspector,
    })

    local inspectorSub = new("TextLabel", {
        Size = UDim2.new(1, -28, 0, 52),
        Position = UDim2.fromOffset(14, 68),
        BackgroundTransparency = 1,
        Text = "Interact with a control to inspect its state.",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = inspector,
    })

    local stateCard = new("Frame", {
        Size = UDim2.new(1, -28, 0, 78),
        Position = UDim2.fromOffset(14, 130),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = inspector,
    })
    corner(stateCard, 10)
    stroke(stateCard, Theme.StrokeSoft, 0.42, 1)

    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.fromOffset(10, 9),
        BackgroundTransparency = 1,
        Text = "CURRENT STATE",
        Font = Enum.Font.GothamBold,
        TextSize = 7,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = stateCard,
    })

    local stateDot = new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.fromOffset(10, 43),
        BackgroundColor3 = Theme.Green,
        BorderSizePixel = 0,
        Parent = stateCard,
    })
    corner(stateDot, 6)

    local stateValue = new("TextLabel", {
        Size = UDim2.new(1, -34, 0, 20),
        Position = UDim2.fromOffset(23, 35),
        BackgroundTransparency = 1,
        Text = "Ready",
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = stateCard,
    })

    local hintCard = new("Frame", {
        Size = UDim2.new(1, -28, 0, 92),
        Position = UDim2.fromOffset(14, 220),
        BackgroundColor3 = Theme.AccentWash,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Parent = inspector,
    })
    corner(hintCard, 10)
    stroke(hintCard, Theme.AccentSoft, 0.5, 1)

    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Text = "LUMI LAB",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hintCard,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 52),
        Position = UDim2.fromOffset(10, 30),
        BackgroundTransparency = 1,
        Text = "This panel is contextual. Final builds can show hotkeys, descriptions or previews here.",
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextColor3 = Theme.TextSoft,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = hintCard,
    })

    local overlay = new("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = main,
    })

    local window = setmetatable({
        Root = root,
        Main = main,
        Shadow = shadow,
        Topbar = topbar,
        Navigation = nav,
        Workspace = workspace,
        InspectorTitle = inspectorTitle,
        InspectorSub = inspectorSub,
        StateValue = stateValue,
        StateDot = stateDot,
        Overlay = overlay,
        Tabs = {},
        ActiveTab = nil,
        OpenDropdown = nil,
        _destroyed = false,
    }, Window)

    closeButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    local dragging = false
    local dragStart
    local mainStart
    local shadowStart

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            mainStart = main.Position
            shadowStart = shadow.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + delta.X, mainStart.Y.Scale, mainStart.Y.Offset + delta.Y)
            shadow.Position = UDim2.new(shadowStart.X.Scale, shadowStart.X.Offset + delta.X, shadowStart.Y.Scale, shadowStart.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
        end
    end)

    table.insert(self._windows, window)
    return window
end

function Window:_closeDropdown()
    if self.OpenDropdown then
        self.OpenDropdown:Destroy()
        self.OpenDropdown = nil
    end
end

function Window:SetDetails(title, description, status)
    if self._destroyed then return end
    self.InspectorTitle.Text = title or "Inspector"
    self.InspectorSub.Text = description or ""
    self.StateValue.Text = status or "Ready"
end

function Window:SelectTab(tab)
    if self._destroyed or self.ActiveTab == tab then return end
    self:_closeDropdown()

    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        item.Indicator.Visible = active
        tween(item.Button, 0.12, {
            BackgroundColor3 = active and Theme.Surface2 or Theme.Sidebar,
            TextColor3 = active and Theme.Text or Theme.Muted,
        })
        if item.Icon then
            tween(item.Icon, 0.12, {
                BackgroundColor3 = active and Theme.AccentWash or Theme.Surface2,
            })
        end
    end

    self.ActiveTab = tab
    self:SetDetails(tab.Name, "Workspace selected. Interact with a control to inspect its current state.", "Tab active")
end

function Window:AddTab(name)
    local index = #self.Tabs + 1
    local kind = index == 1 and "home" or (index == 2 and "player" or "visuals")

    local button = new("TextButton", {
        Name = tostring(name) .. "TabButton",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Sidebar,
        AutoButtonColor = false,
        Text = "        " .. tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Navigation,
    })
    corner(button, 9)

    local icon = makeMiniIcon(button, kind, false)
    icon.Position = UDim2.fromOffset(9, 10)

    local indicator = new("Frame", {
        Size = UDim2.fromOffset(2, 20),
        Position = UDim2.new(0, 2, 0.5, -10),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    })
    corner(indicator, 2)

    local page = new("ScrollingFrame", {
        Name = tostring(name) .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.AccentSoft,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Workspace,
    })
    padding(page, 20, 20, 18, 20)
    list(page, 12)

    local header = new("Frame", {
        Name = "PageHeader",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = page,
        LayoutOrder = 0,
    })

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 28),
        BackgroundTransparency = 1,
        Text = "Tune the workspace and preview interactions.",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local tab = setmetatable({
        Name = tostring(name),
        Window = self,
        Button = button,
        Icon = icon,
        Indicator = indicator,
        Page = page,
        Sections = {},
    }, Tab)

    table.insert(self.Tabs, tab)

    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, 0.1, {BackgroundColor3 = Theme.Surface})
        end
    end)
    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, 0.1, {BackgroundColor3 = Theme.Sidebar})
        end
    end)
    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function Tab:AddSection(name)
    local sectionFrame = new("Frame", {
        Name = tostring(name) .. "Section",
        Size = UDim2.new(1, 0, 0, 68),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Page,
        LayoutOrder = #self.Sections + 1,
    })
    corner(sectionFrame, 12)
    stroke(sectionFrame, Theme.StrokeSoft, 0.32, 1)
    padding(sectionFrame, 12, 12, 10, 12)

    local content = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = sectionFrame,
    })
    list(content, 7)

    local heading = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Parent = content,
        LayoutOrder = 0,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -80, 0, 17),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = heading,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -80, 0, 12),
        Position = UDim2.fromOffset(0, 18),
        BackgroundTransparency = 1,
        Text = "Prototype controls",
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextColor3 = Theme.Muted2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = heading,
    })

    local tag = new("TextLabel", {
        Size = UDim2.fromOffset(58, 20),
        Position = UDim2.new(1, -58, 0, 1),
        BackgroundColor3 = Theme.AccentWash,
        BorderSizePixel = 0,
        Text = "LIVE",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Accent,
        Parent = heading,
    })
    corner(tag, 6)
    stroke(tag, Theme.AccentSoft, 0.55, 1)

    local section = setmetatable({
        Name = tostring(name),
        Tab = self,
        Frame = sectionFrame,
        Content = content,
        _order = 1,
    }, Section)

    table.insert(self.Sections, section)
    return section
end

function Section:_baseRow(name, height, description)
    self._order += 1
    local row = new("Frame", {
        Name = tostring(name) .. "Row",
        Size = UDim2.new(1, 0, 0, height or 52),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Parent = self.Content,
        LayoutOrder = self._order,
    })
    corner(row, 9)
    stroke(row, Theme.StrokeSoft, 0.62, 1)

    new("TextLabel", {
        Size = UDim2.new(0.54, -12, 0, 17),
        Position = UDim2.fromOffset(12, description and 9 or math.floor(((height or 52) - 17) / 2)),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    if description then
        new("TextLabel", {
            Size = UDim2.new(0.62, -12, 0, 13),
            Position = UDim2.fromOffset(12, 27),
            BackgroundTransparency = 1,
            Text = tostring(description),
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextColor3 = Theme.Muted2,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
    end

    return row
end

function Section:AddToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local value = options.Default == true
    local row = self:_baseRow(name, 54, options.Description or "Enable or disable this option.")

    local switch = new("TextButton", {
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = value and Theme.AccentSoft or Theme.Surface3,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    corner(switch, 12)
    stroke(switch, value and Theme.AccentSoft or Theme.Stroke, 0.4, 1)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = value and Theme.Accent or Theme.Muted,
        BorderSizePixel = 0,
        Parent = switch,
    })
    corner(knob, 9)

    local function render()
        tween(switch, 0.14, {BackgroundColor3 = value and Theme.AccentSoft or Theme.Surface3})
        tween(knob, 0.14, {
            Position = value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = value and Theme.Accent or Theme.Muted,
        })
    end

    switch.MouseButton1Click:Connect(function()
        value = not value
        render()
        self.Tab.Window:SetDetails(name, value and "This option is currently enabled." or "This option is currently disabled.", value and "Enabled" or "Disabled")
        safeCallback(options.Callback, value)
    end)

    return {Row = row, Get = function() return value end}
end

function Section:AddSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = tonumber(options.Min) or 0
    local max = tonumber(options.Max) or 100
    if max <= min then max = min + 1 end
    local value = math.clamp(tonumber(options.Default) or min, min, max)

    local row = self:_baseRow(name, 64, options.Description or "Adjust the value precisely.")

    local valueBox = new("Frame", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0, 8),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(valueBox, 6)

    local valueLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(math.floor(value + 0.5)),
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = Theme.Accent,
        Parent = valueBox,
    })

    local track = new("Frame", {
        Size = UDim2.new(1, -24, 0, 4),
        Position = UDim2.fromOffset(12, 49),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(track, 4)

    local alpha = (value - min) / (max - min)
    local fill = new("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, 4)

    local thumb = new("Frame", {
        Size = UDim2.fromOffset(11, 11),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(thumb, 6)
    stroke(thumb, Theme.AccentSoft, 0, 1)

    local hitbox = new("TextButton", {
        Size = UDim2.new(1, 8, 0, 22),
        Position = UDim2.new(0, -4, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "",
        Parent = track,
    })

    local dragging = false

    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local a = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        value = min + ((max - min) * a)
        valueLabel.Text = tostring(math.floor(value + 0.5))
        fill.Size = UDim2.new(a, 0, 1, 0)
        thumb.Position = UDim2.new(a, 0, 0.5, 0)
        self.Tab.Window:SetDetails(name, "Current value: " .. valueLabel.Text .. " / " .. tostring(max), "Adjusting")
        safeCallback(options.Callback, value)
    end

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {Row = row, Get = function() return value end}
end

function Section:AddButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local row = self:_baseRow(name, 52, options.Description or "Run this placeholder action.")

    local action = new("TextButton", {
        Size = UDim2.fromOffset(76, 28),
        Position = UDim2.new(1, -88, 0.5, -14),
        BackgroundColor3 = Theme.AccentWash,
        AutoButtonColor = false,
        Text = "RUN",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Accent,
        Parent = row,
    })
    corner(action, 7)
    stroke(action, Theme.AccentSoft, 0.48, 1)

    action.MouseEnter:Connect(function()
        tween(action, 0.1, {BackgroundColor3 = Theme.AccentSoft, TextColor3 = Theme.Text})
    end)
    action.MouseLeave:Connect(function()
        tween(action, 0.1, {BackgroundColor3 = Theme.AccentWash, TextColor3 = Theme.Accent})
    end)
    action.MouseButton1Click:Connect(function()
        self.Tab.Window:SetDetails(name, "The placeholder action was executed.", "Action complete")
        safeCallback(options.Callback)
    end)

    return {Row = row}
end

function Section:AddDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local values = options.Values or {}
    local selected = options.Default
    if selected == nil then selected = values[1] end

    local row = self:_baseRow(name, 54, options.Description or "Choose one available value.")

    local selector = new("TextButton", {
        Size = UDim2.fromOffset(174, 30),
        Position = UDim2.new(1, -186, 0.5, -15),
        BackgroundColor3 = Theme.Surface3,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })
    corner(selector, 7)
    stroke(selector, Theme.Stroke, 0.58, 1)

    local selectedLabel = new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = tostring(selected or "None"),
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = selected and Theme.TextSoft or Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = selector,
    })
    makeChevron(selector, 154, 12, Theme.Muted)

    local function openMenu()
        self.Tab.Window:_closeDropdown()

        local window = self.Tab.Window
        local selectorPos = selector.AbsolutePosition
        local mainPos = window.Main.AbsolutePosition

        local menu = new("Frame", {
            Size = UDim2.fromOffset(174, math.max(#values, 1) * 31 + 10),
            Position = UDim2.fromOffset(
                selectorPos.X - mainPos.X,
                selectorPos.Y - mainPos.Y + selector.AbsoluteSize.Y + 5
            ),
            BackgroundColor3 = Theme.Surface2,
            BorderSizePixel = 0,
            ZIndex = 120,
            Parent = window.Overlay,
        })
        corner(menu, 9)
        stroke(menu, Theme.Stroke, 0.25, 1)
        padding(menu, 5, 5, 5, 5)
        list(menu, 2)

        window.OpenDropdown = menu

        if #values == 0 then
            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "No values",
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextColor3 = Theme.Muted,
                Parent = menu,
                ZIndex = 121,
            })
        else
            for _, item in ipairs(values) do
                local option = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 29),
                    BackgroundColor3 = item == selected and Theme.AccentWash or Theme.Surface2,
                    AutoButtonColor = false,
                    Text = "   " .. tostring(item),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 9,
                    TextColor3 = item == selected and Theme.Accent or Theme.TextSoft,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = menu,
                    ZIndex = 121,
                })
                corner(option, 6)

                option.MouseEnter:Connect(function()
                    tween(option, 0.08, {BackgroundColor3 = Theme.Surface3})
                end)
                option.MouseLeave:Connect(function()
                    tween(option, 0.08, {BackgroundColor3 = item == selected and Theme.AccentWash or Theme.Surface2})
                end)
                option.MouseButton1Click:Connect(function()
                    selected = item
                    selectedLabel.Text = tostring(selected)
                    window:_closeDropdown()
                    self.Tab.Window:SetDetails(name, "Current selection: " .. tostring(selected), "Selection updated")
                    safeCallback(options.Callback, selected)
                end)
            end
        end

        self.Tab.Window:SetDetails(name, "Choose one of " .. tostring(#values) .. " values.", "Menu opened")
    end

    selector.MouseButton1Click:Connect(function()
        if self.Tab.Window.OpenDropdown then
            self.Tab.Window:_closeDropdown()
        else
            openMenu()
        end
    end)

    return {Row = row, Get = function() return selected end}
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self:_closeDropdown()
    if self.Root then self.Root:Destroy() end
end

-- Demo -----------------------------------------------------------------------

local window = Lumi:CreateWindow({Title = "Lumi"})

local home = window:AddTab("Overview")
local player = window:AddTab("Player")
local visuals = window:AddTab("Visuals")

local general = home:AddSection("General")
general:AddToggle({
    Name = "Enable pilot",
    Description = "Master state for the current interface preview.",
    Default = true,
    Callback = function(value)
        print("[Lumi UI] Enable pilot:", value)
    end,
})
general:AddSlider({
    Name = "Intensity",
    Description = "Fine tune the preview strength.",
    Min = 0,
    Max = 100,
    Default = 65,
    Callback = function(value)
        print("[Lumi UI] Intensity:", math.floor(value + 0.5))
    end,
})
general:AddDropdown({
    Name = "Interaction mode",
    Description = "Changes the feel of placeholder interactions.",
    Values = {"Default", "Smooth", "Precise"},
    Default = "Default",
    Callback = function(value)
        print("[Lumi UI] Mode:", value)
    end,
})
general:AddButton({
    Name = "Preview action",
    Description = "Exercises the callback and inspector state.",
    Callback = function()
        print("[Lumi UI] Placeholder action executed")
    end,
})

local movement = player:AddSection("Movement")
movement:AddToggle({
    Name = "Movement placeholder",
    Description = "Example stateful player control.",
    Default = false,
})
movement:AddSlider({
    Name = "Speed placeholder",
    Description = "Example numeric player setting.",
    Min = 1,
    Max = 10,
    Default = 4,
})
movement:AddButton({
    Name = "Reset placeholder",
    Description = "Example action control.",
})

local visual = visuals:AddSection("Presentation")
visual:AddToggle({
    Name = "Overlay placeholder",
    Description = "Example visual visibility switch.",
    Default = false,
})
visual:AddDropdown({
    Name = "Interface style",
    Description = "Example style selector.",
    Values = {"Lumi", "Minimal", "Compact"},
    Default = "Lumi",
})
visual:AddButton({
    Name = "Preview placeholder",
    Description = "Example visual action.",
})

window:SetDetails(
    "Overview",
    "The visual pilot is active. Interact with a control to inspect its current state.",
    "Pilot ready"
)

print("[Lumi UI] Visual pilot v0.3 loaded")

return Lumi
