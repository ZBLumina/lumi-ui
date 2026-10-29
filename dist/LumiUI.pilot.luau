-- Lumi UI v0.1 Pilot
-- Standalone placeholder build for Potassium testing.
-- No game-specific logic. Safe to re-execute: previous pilot root is removed.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ROOT_NAME = "LumiUIPilot_v01"

local Theme = {
    Background = Color3.fromRGB(18, 18, 20),
    Surface = Color3.fromRGB(25, 25, 28),
    Surface2 = Color3.fromRGB(31, 31, 35),
    Surface3 = Color3.fromRGB(38, 38, 43),
    Outline = Color3.fromRGB(58, 56, 54),
    Text = Color3.fromRGB(239, 235, 226),
    Muted = Color3.fromRGB(154, 149, 140),
    Accent = Color3.fromRGB(255, 235, 163),
    AccentSoft = Color3.fromRGB(99, 90, 61),
    Success = Color3.fromRGB(166, 213, 170),
    Danger = Color3.fromRGB(222, 137, 137),
}

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end

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

local function create(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Outline,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent,
    })
end

local function tween(object, duration, properties)
    local info = TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end
    return CoreGui
end

local guiParent = getGuiParent()
local previous = guiParent:FindFirstChild(ROOT_NAME)
if previous then
    previous:Destroy()
end

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
        if window and window.Destroy then
            window:Destroy()
        end
    end
    table.clear(self._windows)
end

function Lumi:CreateWindow(options)
    options = options or {}

    local root = create("ScreenGui", {
        Name = ROOT_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = guiParent,
    })

    local shadow = create("Frame", {
        Name = "Shadow",
        Size = UDim2.fromOffset(870, 530),
        Position = UDim2.new(0.5, -425, 0.5, -250),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Parent = root,
    })
    corner(shadow, 17)

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(860, 520),
        Position = UDim2.new(0.5, -430, 0.5, -260),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
    })
    corner(main, 16)
    stroke(main, Theme.Outline, 0.25, 1)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
    })

    create("TextLabel", {
        Name = "Brand",
        Size = UDim2.new(0, 170, 1, 0),
        Position = UDim2.fromOffset(18, 0),
        BackgroundTransparency = 1,
        Text = string.lower(options.Title or "lumi"),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
    })

    local pilotTag = create("TextLabel", {
        Size = UDim2.fromOffset(74, 24),
        Position = UDim2.new(0, 92, 0.5, -12),
        BackgroundColor3 = Theme.AccentSoft,
        BackgroundTransparency = 0.2,
        Text = "PILOT 0.1",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.Accent,
        Parent = topbar,
    })
    corner(pilotTag, 7)

    local closeButton = create("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -42, 0.5, -16),
        BackgroundColor3 = Theme.Surface2,
        AutoButtonColor = false,
        Text = "x",
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        TextColor3 = Theme.Muted,
        Parent = topbar,
    })
    corner(closeButton, 8)

    closeButton.MouseEnter:Connect(function()
        tween(closeButton, 0.12, {BackgroundColor3 = Color3.fromRGB(68, 40, 42), TextColor3 = Theme.Danger})
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, 0.12, {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Muted})
    end)

    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.fromOffset(0, 48),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = body,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 24),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        Text = "WORKSPACE",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })

    local nav = create("Frame", {
        Name = "Navigation",
        Size = UDim2.new(1, -16, 1, -60),
        Position = UDim2.fromOffset(8, 42),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = nav,
    })

    local workspace = create("Frame", {
        Name = "Workspace",
        Size = UDim2.new(1, -350, 1, 0),
        Position = UDim2.fromOffset(150, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = body,
    })

    local detail = create("Frame", {
        Name = "Detail",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(1, -200, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = body,
    })
    padding(detail, 16, 16, 16, 16)

    local detailTitle = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = "Inspector",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = detail,
    })

    local detailSub = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.fromOffset(0, 30),
        BackgroundTransparency = 1,
        Text = "Select a control to preview its state.",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = detail,
    })

    local statusCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 82),
        Position = UDim2.fromOffset(0, 88),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Parent = detail,
    })
    corner(statusCard, 10)
    stroke(statusCard, Theme.Outline, 0.5, 1)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Text = "STATUS",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusCard,
    })

    local statusValue = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.fromOffset(10, 34),
        BackgroundTransparency = 1,
        Text = "Ready for Potassium",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Success,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusCard,
    })

    local window = setmetatable({
        Root = root,
        Main = main,
        Shadow = shadow,
        Topbar = topbar,
        Navigation = nav,
        Workspace = workspace,
        DetailTitle = detailTitle,
        DetailSub = detailSub,
        StatusValue = statusValue,
        Tabs = {},
        ActiveTab = nil,
        _destroyed = false,
    }, Window)

    closeButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    local dragging = false
    local dragStart
    local startPosition

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart and startPosition then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            shadow.Position = main.Position + UDim2.fromOffset(5, 10)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPosition = nil
        end
    end)

    table.insert(self._windows, window)
    return window
end

function Window:SetDetails(title, description, status)
    if self._destroyed then return end
    self.DetailTitle.Text = title or "Inspector"
    self.DetailSub.Text = description or ""
    self.StatusValue.Text = status or "Ready"
end

function Window:SelectTab(tab)
    if self._destroyed or self.ActiveTab == tab then return end
    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        tween(item.Button, 0.12, {
            BackgroundColor3 = active and Theme.Surface3 or Theme.Surface,
            TextColor3 = active and Theme.Text or Theme.Muted,
        })
        item.Indicator.Visible = active
    end
    self.ActiveTab = tab
    self:SetDetails(tab.Name, "Placeholder workspace for " .. tab.Name .. ".", "Tab active")
end

function Window:AddTab(name)
    local button = create("TextButton", {
        Name = tostring(name) .. "TabButton",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Surface,
        AutoButtonColor = false,
        Text = "   " .. tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Navigation,
    })
    corner(button, 9)

    local indicator = create("Frame", {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 5, 0.5, -9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    })
    corner(indicator, 3)

    local page = create("ScrollingFrame", {
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
    padding(page, 18, 18, 16, 18)
    create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})

    local tab = setmetatable({Name = tostring(name), Window = self, Button = button, Indicator = indicator, Page = page, Sections = {}}, Tab)

    button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
    button.MouseEnter:Connect(function() if self.ActiveTab ~= tab then tween(button, 0.12, {BackgroundColor3 = Theme.Surface2}) end end)
    button.MouseLeave:Connect(function() if self.ActiveTab ~= tab then tween(button, 0.12, {BackgroundColor3 = Theme.Surface}) end end)

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then self:SelectTab(tab) end
    return tab
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self.Root then self.Root:Destroy() end
end

function Tab:AddSection(name)
    local frame = create("Frame", {
        Name = tostring(name) .. "Section",
        Size = UDim2.new(1, 0, 0, 52),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Page,
    })
    corner(frame, 12)
    stroke(frame, Theme.Outline, 0.55, 1)
    padding(frame, 14, 14, 12, 14)

    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        LayoutOrder = 0,
    })
    create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame})

    local section = setmetatable({Name = tostring(name), Tab = self, Frame = frame, _layoutOrder = 0}, Section)
    table.insert(self.Sections, section)
    return section
end

function Section:_nextOrder()
    self._layoutOrder = self._layoutOrder + 1
    return self._layoutOrder
end

function Section:_baseRow(name, height)
    local row = create("Frame", {
        Name = tostring(name) .. "Row",
        Size = UDim2.new(1, 0, 0, height or 42),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Frame,
    })
    corner(row, 9)
    return row
end

function Section:AddButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local row = self:_baseRow(name, 42)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutoButtonColor = false,
        Text = "  " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    create("TextLabel", {Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -32, 0.5, -12), BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent, Parent = row})
    button.MouseButton1Click:Connect(function()
        tween(row, 0.08, {BackgroundColor3 = Theme.AccentSoft})
        task.delay(0.10, function() if row.Parent then tween(row, 0.12, {BackgroundColor3 = Theme.Surface2}) end end)
        self.Tab.Window:SetDetails(name, "Placeholder button callback fired.", "Action executed")
        safeCallback(options.Callback)
    end)
    return {Row = row, Button = button}
end

function Section:AddToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local value = options.Default == true
    local row = self:_baseRow(name, 44)
    create("TextLabel", {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
    local switch = create("TextButton", {Size = UDim2.fromOffset(42, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = value and Theme.AccentSoft or Theme.Surface3, AutoButtonColor = false, Text = "", Parent = row})
    corner(switch, 11)
    local knob = create("Frame", {Size = UDim2.fromOffset(16, 16), Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = value and Theme.Accent or Theme.Muted, BorderSizePixel = 0, Parent = switch})
    corner(knob, 8)
    local function render()
        tween(switch, 0.14, {BackgroundColor3 = value and Theme.AccentSoft or Theme.Surface3})
        tween(knob, 0.14, {Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = value and Theme.Accent or Theme.Muted})
    end
    switch.MouseButton1Click:Connect(function()
        value = not value
        render()
        self.Tab.Window:SetDetails(name, "Toggle state: " .. tostring(value), value and "Enabled" or "Disabled")
        safeCallback(options.Callback, value)
    end)
    return {Row = row, Get = function() return value end, Set = function(_, newValue) value = newValue == true; render() end}
end

function Section:AddSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = tonumber(options.Min) or 0
    local max = tonumber(options.Max) or 100
    if max < min then min, max = max, min end
    if max == min then max = min + 1 end
    local value = math.clamp(tonumber(options.Default) or min, min, max)
    local row = self:_baseRow(name, 62)
    create("TextLabel", {Size = UDim2.new(1, -74, 0, 26), Position = UDim2.fromOffset(12, 4), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
    local valueLabel = create("TextLabel", {Size = UDim2.fromOffset(54, 26), Position = UDim2.new(1, -66, 0, 4), BackgroundTransparency = 1, Text = tostring(math.floor(value + 0.5)), Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = row})
    local track = create("Frame", {Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 1, -18), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = row})
    corner(track, 3)
    local fill = create("Frame", {Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track})
    corner(fill, 3)
    local hitbox = create("TextButton", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0.5, -11), BackgroundTransparency = 1, Text = "", Parent = track})
    local dragging = false
    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        value = min + ((max - min) * alpha)
        valueLabel.Text = tostring(math.floor(value + 0.5))
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        self.Tab.Window:SetDetails(name, "Slider value: " .. valueLabel.Text, "Adjusting")
        safeCallback(options.Callback, value)
    end
    hitbox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(input.Position.X) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    return {Row = row, Get = function() return value end}
end

function Section:AddDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local values = options.Values or {}
    local selected = options.Default
    if selected == nil then selected = values[1] end
    local row = self:_baseRow(name, 46)
    row.ClipsDescendants = false
    row.ZIndex = 10
    create("TextLabel", {Size = UDim2.new(0.44, -12, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
    local selector = create("TextButton", {Size = UDim2.new(0.52, -12, 0, 30), Position = UDim2.new(0.48, 0, 0.5, -15), BackgroundColor3 = Theme.Surface3, AutoButtonColor = false, Text = tostring(selected or "None") .. "   v", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = selected and Theme.Text or Theme.Muted, Parent = row, ZIndex = 12})
    corner(selector, 8)
    local list = create("Frame", {Size = UDim2.new(1, 0, 0, math.max(#values, 1) * 30 + 8), Position = UDim2.new(0, 0, 1, 5), BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Visible = false, Parent = selector, ZIndex = 20})
    corner(list, 8)
    stroke(list, Theme.Outline, 0.25, 1)
    padding(list, 4, 4, 4, 4)
    create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), Parent = list})
    if #values == 0 then
        create("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "No values", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Muted, Parent = list, ZIndex = 21})
    else
        for _, item in ipairs(values) do
            local option = create("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Surface3, AutoButtonColor = false, Text = tostring(item), Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Text, Parent = list, ZIndex = 21})
            corner(option, 6)
            option.MouseButton1Click:Connect(function()
                selected = item
                selector.Text = tostring(selected) .. "   v"
                selector.TextColor3 = Theme.Text
                list.Visible = false
                self.Tab.Window:SetDetails(name, "Selected: " .. tostring(selected), "Selection updated")
                safeCallback(options.Callback, selected)
            end)
        end
    end
    selector.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        self.Tab.Window:SetDetails(name, "Placeholder dropdown with " .. tostring(#values) .. " values.", list.Visible and "Opened" or "Closed")
    end)
    return {Row = row, Get = function() return selected end}
end

local window = Lumi:CreateWindow({Title = "Lumi"})
local home = window:AddTab("Home")
local player = window:AddTab("Player")
local visuals = window:AddTab("Visuals")

local general = home:AddSection("General")
general:AddToggle({Name = "Enable pilot", Default = true, Callback = function(value) print("[Lumi UI] Enable pilot:", value) end})
general:AddSlider({Name = "Intensity", Min = 0, Max = 100, Default = 65, Callback = function(value) print("[Lumi UI] Intensity:", math.floor(value + 0.5)) end})
general:AddDropdown({Name = "Mode", Values = {"Default", "Smooth", "Precise"}, Default = "Default", Callback = function(value) print("[Lumi UI] Mode:", value) end})
general:AddButton({Name = "Run placeholder action", Callback = function() print("[Lumi UI] Placeholder action executed") end})

local playerSection = player:AddSection("Player placeholders")
playerSection:AddToggle({Name = "Movement placeholder", Default = false})
playerSection:AddSlider({Name = "Speed placeholder", Min = 1, Max = 10, Default = 4})
playerSection:AddButton({Name = "Reset placeholder"})

local visualSection = visuals:AddSection("Visual placeholders")
visualSection:AddToggle({Name = "Overlay placeholder", Default = false})
visualSection:AddDropdown({Name = "Style", Values = {"Lumi", "Minimal", "Compact"}, Default = "Lumi"})
visualSection:AddButton({Name = "Preview placeholder"})

window:SetDetails("Lumi UI", "Standalone placeholder build loaded successfully.", "Pilot ready")
print("[Lumi UI] Pilot v0.1 loaded")

return Lumi
