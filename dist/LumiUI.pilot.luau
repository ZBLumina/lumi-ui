-- Lumi UI v0.2 Visual Pilot
-- Premium desktop-style redesign for Potassium testing.
-- Standalone, no game-specific logic, safe to re-execute.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ROOT_NAME = "LumiUIPilot_v01"

local Theme = {
    Canvas = Color3.fromRGB(14, 14, 16),
    Sidebar = Color3.fromRGB(18, 18, 20),
    Panel = Color3.fromRGB(22, 22, 25),
    PanelSoft = Color3.fromRGB(26, 26, 30),
    Control = Color3.fromRGB(30, 30, 34),
    ControlHover = Color3.fromRGB(36, 35, 39),
    Outline = Color3.fromRGB(63, 60, 55),
    OutlineSoft = Color3.fromRGB(46, 44, 41),
    Text = Color3.fromRGB(243, 239, 231),
    TextSoft = Color3.fromRGB(198, 191, 180),
    Muted = Color3.fromRGB(137, 132, 124),
    Accent = Color3.fromRGB(255, 235, 163),
    AccentDim = Color3.fromRGB(91, 82, 54),
    AccentWash = Color3.fromRGB(51, 47, 35),
    Success = Color3.fromRGB(157, 211, 169),
    Danger = Color3.fromRGB(225, 139, 139),
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
        Transparency = transparency == nil and 0 or transparency,
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
    if not object or not object.Parent then
        return nil
    end

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

local function bindHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, {BackgroundColor3 = hoverColor})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.12, {BackgroundColor3 = normalColor})
    end)
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
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = guiParent,
    })

    local mainSize = Vector2.new(920, 548)

    local shadow = create("Frame", {
        Name = "Shadow",
        Size = UDim2.fromOffset(mainSize.X + 10, mainSize.Y + 10),
        Position = UDim2.new(0.5, -(mainSize.X / 2) + 5, 0.5, -(mainSize.Y / 2) + 10),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.58,
        BorderSizePixel = 0,
        Parent = root,
        ZIndex = 1,
    })
    corner(shadow, 18)

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(mainSize.X, mainSize.Y),
        Position = UDim2.new(0.5, -(mainSize.X / 2), 0.5, -(mainSize.Y / 2)),
        BackgroundColor3 = Theme.Canvas,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = root,
        ZIndex = 2,
    })
    corner(main, 16)
    stroke(main, Theme.OutlineSoft, 0.15, 1)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.Canvas,
        BorderSizePixel = 0,
        Parent = main,
        ZIndex = 5,
    })

    create("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 1, -1),
        BackgroundColor3 = Theme.OutlineSoft,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Parent = topbar,
        ZIndex = 6,
    })

    local brandMark = create("Frame", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.AccentWash,
        BorderSizePixel = 0,
        Parent = topbar,
        ZIndex = 7,
    })
    corner(brandMark, 8)
    stroke(brandMark, Theme.AccentDim, 0.2, 1)

    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "L",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Accent,
        Parent = brandMark,
        ZIndex = 8,
    })

    create("TextLabel", {
        Name = "Brand",
        Size = UDim2.fromOffset(110, 22),
        Position = UDim2.fromOffset(52, 11),
        BackgroundTransparency = 1,
        Text = string.lower(options.Title or "lumi"),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
        ZIndex = 7,
    })

    create("TextLabel", {
        Size = UDim2.fromOffset(130, 16),
        Position = UDim2.fromOffset(52, 31),
        BackgroundTransparency = 1,
        Text = "interface preview",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar,
        ZIndex = 7,
    })

    local closeButton = create("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -44, 0, 14),
        BackgroundColor3 = Theme.PanelSoft,
        AutoButtonColor = false,
        Text = "×",
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        TextColor3 = Theme.Muted,
        Parent = topbar,
        ZIndex = 8,
    })
    corner(closeButton, 8)
    stroke(closeButton, Theme.OutlineSoft, 0.45, 1)

    closeButton.MouseEnter:Connect(function()
        tween(closeButton, 0.12, {
            BackgroundColor3 = Color3.fromRGB(55, 34, 36),
            TextColor3 = Theme.Danger,
        })
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, 0.12, {
            BackgroundColor3 = Theme.PanelSoft,
            TextColor3 = Theme.Muted,
        })
    end)

    local body = create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -58),
        Position = UDim2.fromOffset(0, 58),
        BackgroundTransparency = 1,
        Parent = main,
        ZIndex = 3,
    })

    local sidebarWidth = 164
    local detailWidth = 202

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
        ZIndex = 4,
    })

    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.OutlineSoft,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = sidebar,
        ZIndex = 5,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.fromOffset(15, 18),
        BackgroundTransparency = 1,
        Text = "NAVIGATION",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
        ZIndex = 6,
    })

    local nav = create("Frame", {
        Name = "Navigation",
        Size = UDim2.new(1, -18, 1, -116),
        Position = UDim2.fromOffset(9, 48),
        BackgroundTransparency = 1,
        Parent = sidebar,
        ZIndex = 6,
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = nav,
    })

    local footer = create("Frame", {
        Size = UDim2.new(1, -18, 0, 48),
        Position = UDim2.new(0, 9, 1, -58),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = sidebar,
        ZIndex = 6,
    })
    corner(footer, 10)
    stroke(footer, Theme.OutlineSoft, 0.5, 1)

    local footerDot = create("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.fromOffset(10, 11),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel = 0,
        Parent = footer,
        ZIndex = 7,
    })
    corner(footerDot, 6)

    create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.fromOffset(24, 6),
        BackgroundTransparency = 1,
        Text = "Potassium",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
        ZIndex = 7,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.fromOffset(10, 26),
        BackgroundTransparency = 1,
        Text = "visual pilot · v0.2",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
        ZIndex = 7,
    })

    local workspace = create("Frame", {
        Name = "Workspace",
        Size = UDim2.new(1, -(sidebarWidth + detailWidth), 1, 0),
        Position = UDim2.fromOffset(sidebarWidth, 0),
        BackgroundColor3 = Theme.Canvas,
        BorderSizePixel = 0,
        Parent = body,
        ZIndex = 4,
    })

    local detail = create("Frame", {
        Name = "Detail",
        Size = UDim2.new(0, detailWidth, 1, 0),
        Position = UDim2.new(1, -detailWidth, 0, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
        ZIndex = 4,
    })

    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.OutlineSoft,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = detail,
        ZIndex = 5,
    })

    padding(detail, 16, 16, 18, 16)

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "CONTEXT",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = detail,
        ZIndex = 6,
    })

    local detailTitle = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 29),
        BackgroundTransparency = 1,
        Text = "Lumi UI",
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = detail,
        ZIndex = 6,
    })

    local detailSub = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.fromOffset(0, 58),
        BackgroundTransparency = 1,
        Text = "Move through the pilot to inspect component state.",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = detail,
        ZIndex = 6,
    })

    local statusCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 84),
        Position = UDim2.fromOffset(0, 132),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = detail,
        ZIndex = 6,
    })
    corner(statusCard, 11)
    stroke(statusCard, Theme.OutlineSoft, 0.35, 1)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.fromOffset(10, 12),
        BackgroundTransparency = 1,
        Text = "CURRENT STATE",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusCard,
        ZIndex = 7,
    })

    local statusDot = create("Frame", {
        Size = UDim2.fromOffset(7, 7),
        Position = UDim2.fromOffset(11, 47),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel = 0,
        Parent = statusCard,
        ZIndex = 7,
    })
    corner(statusDot, 7)

    local statusValue = create("TextLabel", {
        Size = UDim2.new(1, -34, 0, 22),
        Position = UDim2.fromOffset(26, 39),
        BackgroundTransparency = 1,
        Text = "Pilot ready",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statusCard,
        ZIndex = 7,
    })

    local overlay = create("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Parent = main,
        ZIndex = 100,
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
        StatusDot = statusDot,
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
    local dragStart = nil
    local startPosition = nil

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
            local newPosition = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
            main.Position = newPosition
            shadow.Position = UDim2.new(
                newPosition.X.Scale,
                newPosition.X.Offset + 5,
                newPosition.Y.Scale,
                newPosition.Y.Offset + 10
            )
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
    if self._destroyed then
        return
    end

    self.DetailTitle.Text = title or "Lumi UI"
    self.DetailSub.Text = description or ""
    self.StatusValue.Text = status or "Ready"
end

function Window:_closeDropdown()
    if self.OpenDropdown and self.OpenDropdown.Parent then
        self.OpenDropdown:Destroy()
    end
    self.OpenDropdown = nil
end

function Window:SelectTab(tab)
    if self._destroyed or self.ActiveTab == tab then
        return
    end

    self:_closeDropdown()

    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Page.Visible = active
        item.Indicator.Visible = active
        item.Icon.TextColor3 = active and Theme.Accent or Theme.Muted
        item.Button.TextColor3 = active and Theme.Text or Theme.TextSoft
        tween(item.Button, 0.12, {
            BackgroundColor3 = active and Theme.PanelSoft or Theme.Sidebar,
        })
    end

    self.ActiveTab = tab
    self:SetDetails(tab.Name, "Workspace selected. Interact with a control to inspect its current state.", "Tab active")
end

function Window:AddTab(name)
    local button = create("TextButton", {
        Name = tostring(name) .. "TabButton",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Sidebar,
        AutoButtonColor = false,
        Text = "      " .. tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Navigation,
        ZIndex = 7,
    })
    corner(button, 9)

    local indicator = create("Frame", {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 5, 0.5, -9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
        ZIndex = 8,
    })
    corner(indicator, 3)

    local icon = create("TextLabel", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(0, 13, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "◆",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Theme.Muted,
        Parent = button,
        ZIndex = 8,
    })

    button.MouseEnter:Connect(function()
        if self.ActiveTab == nil or self.ActiveTab.Button ~= button then
            tween(button, 0.12, {BackgroundColor3 = Theme.Panel})
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab == nil or self.ActiveTab.Button ~= button then
            tween(button, 0.12, {BackgroundColor3 = Theme.Sidebar})
        end
    end)

    local page = create("ScrollingFrame", {
        Name = tostring(name) .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.AccentDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Workspace,
        ZIndex = 5,
    })
    padding(page, 20, 20, 18, 22)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })

    local header = create("Frame", {
        Name = "PageHeader",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = page,
        ZIndex = 6,
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
        ZIndex = 7,
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 31),
        BackgroundTransparency = 1,
        Text = "Configure and preview this workspace.",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
        ZIndex = 7,
    })

    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = page,
        ZIndex = 6,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content,
    })

    local tab = setmetatable({
        Name = tostring(name),
        Window = self,
        Button = button,
        Indicator = indicator,
        Icon = icon,
        Page = page,
        Content = content,
        Sections = {},
    }, Tab)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Tab:AddSection(name)
    local sectionFrame = create("Frame", {
        Name = tostring(name) .. "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = self.Content,
        ZIndex = 7,
    })
    corner(sectionFrame, 12)
    stroke(sectionFrame, Theme.OutlineSoft, 0.35, 1)
    padding(sectionFrame, 12, 12, 10, 12)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sectionFrame,
    })

    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = tostring(name),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
        Parent = sectionFrame,
        ZIndex = 8,
    })

    local section = setmetatable({
        Name = tostring(name),
        Tab = self,
        Frame = sectionFrame,
        Title = title,
        _order = 0,
    }, Section)

    table.insert(self.Sections, section)
    return section
end

function Section:_nextOrder()
    self._order += 1
    return self._order
end

function Section:_baseRow(name, height)
    local row = create("Frame", {
        Name = tostring(name) .. "Row",
        Size = UDim2.new(1, 0, 0, height or 46),
        BackgroundColor3 = Theme.PanelSoft,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
        Parent = self.Frame,
        ZIndex = 8,
    })
    corner(row, 9)
    stroke(row, Theme.OutlineSoft, 0.65, 1)
    return row
end

function Section:AddButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local row = self:_baseRow(name, 44)

    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
        ZIndex = 9,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -58, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
        ZIndex = 10,
    })

    local actionChip = create("Frame", {
        Size = UDim2.fromOffset(28, 24),
        Position = UDim2.new(1, -38, 0.5, -12),
        BackgroundColor3 = Theme.AccentWash,
        BorderSizePixel = 0,
        Parent = row,
        ZIndex = 10,
    })
    corner(actionChip, 7)
    stroke(actionChip, Theme.AccentDim, 0.35, 1)

    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "›",
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = Theme.Accent,
        Parent = actionChip,
        ZIndex = 11,
    })

    button.MouseEnter:Connect(function()
        tween(row, 0.12, {BackgroundColor3 = Theme.ControlHover})
    end)
    button.MouseLeave:Connect(function()
        tween(row, 0.12, {BackgroundColor3 = Theme.PanelSoft})
    end)
    button.MouseButton1Click:Connect(function()
        self.Tab.Window:SetDetails(name, "Action control triggered from the current section.", "Action executed")
        safeCallback(options.Callback)
    end)

    return {Row = row}
end

function Section:AddToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local value = options.Default == true
    local row = self:_baseRow(name, 48)

    create("TextLabel", {
        Size = UDim2.new(1, -76, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
        ZIndex = 9,
    })

    local toggle = create("TextButton", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = value and Theme.AccentDim or Theme.Control,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
        ZIndex = 10,
    })
    corner(toggle, 11)
    stroke(toggle, value and Theme.AccentDim or Theme.OutlineSoft, 0.25, 1)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = value and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = value and Theme.Accent or Theme.Muted,
        BorderSizePixel = 0,
        Parent = toggle,
        ZIndex = 11,
    })
    corner(knob, 8)

    local function render(animate)
        local knobPosition = value and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        local toggleColor = value and Theme.AccentDim or Theme.Control
        local knobColor = value and Theme.Accent or Theme.Muted

        if animate then
            tween(toggle, 0.14, {BackgroundColor3 = toggleColor})
            tween(knob, 0.14, {Position = knobPosition, BackgroundColor3 = knobColor})
        else
            toggle.BackgroundColor3 = toggleColor
            knob.Position = knobPosition
            knob.BackgroundColor3 = knobColor
        end
    end

    toggle.MouseButton1Click:Connect(function()
        value = not value
        render(true)
        self.Tab.Window:SetDetails(name, value and "This option is currently enabled." or "This option is currently disabled.", value and "Enabled" or "Disabled")
        safeCallback(options.Callback, value)
    end)

    return {
        Row = row,
        Get = function()
            return value
        end,
        Set = function(_, newValue)
            value = newValue == true
            render(true)
        end,
    }
end

function Section:AddSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = tonumber(options.Min) or 0
    local max = tonumber(options.Max) or 100

    if max <= min then
        max = min + 1
    end

    local value = math.clamp(tonumber(options.Default) or min, min, max)
    local row = self:_baseRow(name, 68)

    create("TextLabel", {
        Size = UDim2.new(1, -78, 0, 26),
        Position = UDim2.fromOffset(12, 6),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
        ZIndex = 9,
    })

    local valuePill = create("Frame", {
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -58, 0, 7),
        BackgroundColor3 = Theme.Control,
        BorderSizePixel = 0,
        Parent = row,
        ZIndex = 9,
    })
    corner(valuePill, 7)

    local valueLabel = create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(math.floor(value + 0.5)),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Theme.Accent,
        Parent = valuePill,
        ZIndex = 10,
    })

    local track = create("Frame", {
        Size = UDim2.new(1, -24, 0, 5),
        Position = UDim2.fromOffset(12, 48),
        BackgroundColor3 = Theme.Control,
        BorderSizePixel = 0,
        Parent = row,
        ZIndex = 9,
    })
    corner(track, 3)

    local alpha = (value - min) / (max - min)
    local fill = create("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
        ZIndex = 10,
    })
    corner(fill, 3)

    local thumb = create("Frame", {
        Size = UDim2.fromOffset(11, 11),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
        ZIndex = 11,
    })
    corner(thumb, 6)
    stroke(thumb, Color3.fromRGB(255, 248, 215), 0.15, 1)

    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = track,
        ZIndex = 12,
    })

    local dragging = false

    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local nextAlpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        value = min + ((max - min) * nextAlpha)
        valueLabel.Text = tostring(math.floor(value + 0.5))
        fill.Size = UDim2.new(nextAlpha, 0, 1, 0)
        thumb.Position = UDim2.new(nextAlpha, 0, 0.5, 0)
        self.Tab.Window:SetDetails(name, "Adjust this value between " .. tostring(min) .. " and " .. tostring(max) .. ".", "Value · " .. valueLabel.Text)
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

    return {
        Row = row,
        Get = function()
            return value
        end,
    }
end

function Section:AddDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local values = options.Values or {}
    local selected = options.Default

    if selected == nil then
        selected = values[1]
    end

    local row = self:_baseRow(name, 52)

    create("TextLabel", {
        Size = UDim2.new(0.42, -12, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
        ZIndex = 9,
    })

    local selector = create("TextButton", {
        Size = UDim2.new(0.54, -12, 0, 30),
        Position = UDim2.new(0.46, 0, 0.5, -15),
        BackgroundColor3 = Theme.Control,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
        ZIndex = 10,
    })
    corner(selector, 8)
    stroke(selector, Theme.OutlineSoft, 0.6, 1)
    bindHover(selector, Theme.Control, Theme.ControlHover)

    local selectedLabel = create("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = tostring(selected or "None"),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = selected and Theme.TextSoft or Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = selector,
        ZIndex = 11,
    })

    local chevron = create("TextLabel", {
        Size = UDim2.fromOffset(22, 30),
        Position = UDim2.new(1, -27, 0, 0),
        BackgroundTransparency = 1,
        Text = "⌄",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Muted,
        Parent = selector,
        ZIndex = 11,
    })

    local function openMenu()
        local window = self.Tab.Window
        window:_closeDropdown()

        local menuHeight = math.max(#values, 1) * 30 + 10
        local menu = create("Frame", {
            Name = "DropdownMenu",
            Size = UDim2.fromOffset(selector.AbsoluteSize.X, menuHeight),
            Position = UDim2.fromOffset(
                selector.AbsolutePosition.X - window.Main.AbsolutePosition.X,
                selector.AbsolutePosition.Y - window.Main.AbsolutePosition.Y + selector.AbsoluteSize.Y + 5
            ),
            BackgroundColor3 = Theme.PanelSoft,
            BorderSizePixel = 0,
            Parent = window.Overlay,
            ZIndex = 120,
        })
        corner(menu, 9)
        stroke(menu, Theme.Outline, 0.25, 1)
        padding(menu, 5, 5, 5, 5)

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 2),
            Parent = menu,
        })

        window.OpenDropdown = menu
        chevron.Text = "⌃"

        local function closeMenu()
            window:_closeDropdown()
            chevron.Text = "⌄"
        end

        if #values == 0 then
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "No values",
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextColor3 = Theme.Muted,
                Parent = menu,
                ZIndex = 121,
            })
        else
            for _, item in ipairs(values) do
                local option = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = item == selected and Theme.AccentWash or Theme.PanelSoft,
                    AutoButtonColor = false,
                    Text = "   " .. tostring(item),
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextColor3 = item == selected and Theme.Accent or Theme.TextSoft,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = menu,
                    ZIndex = 121,
                })
                corner(option, 6)

                option.MouseEnter:Connect(function()
                    tween(option, 0.1, {BackgroundColor3 = Theme.ControlHover})
                end)

                option.MouseLeave:Connect(function()
                    tween(option, 0.1, {BackgroundColor3 = item == selected and Theme.AccentWash or Theme.PanelSoft})
                end)

                option.MouseButton1Click:Connect(function()
                    selected = item
                    selectedLabel.Text = tostring(selected)
                    selectedLabel.TextColor3 = Theme.TextSoft
                    closeMenu()
                    self.Tab.Window:SetDetails(name, "Current selection: " .. tostring(selected) .. ".", "Selection updated")
                    safeCallback(options.Callback, selected)
                end)
            end
        end

        self.Tab.Window:SetDetails(name, "Choose one of " .. tostring(#values) .. " available values.", "Menu opened")
    end

    selector.MouseButton1Click:Connect(function()
        if self.Tab.Window.OpenDropdown then
            self.Tab.Window:_closeDropdown()
            chevron.Text = "⌄"
            self.Tab.Window:SetDetails(name, "Dropdown closed without changing the current selection.", "Menu closed")
        else
            openMenu()
        end
    end)

    return {
        Row = row,
        Get = function()
            return selected
        end,
    }
end

function Window:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self:_closeDropdown()

    if self.Root then
        self.Root:Destroy()
    end
end

-- Demo content ---------------------------------------------------------------

local window = Lumi:CreateWindow({Title = "Lumi"})

local home = window:AddTab("Home")
local player = window:AddTab("Player")
local visuals = window:AddTab("Visuals")

local general = home:AddSection("General")
general:AddToggle({
    Name = "Enable pilot",
    Default = true,
    Callback = function(value)
        print("[Lumi UI] Enable pilot:", value)
    end,
})
general:AddSlider({
    Name = "Intensity",
    Min = 0,
    Max = 100,
    Default = 65,
    Callback = function(value)
        print("[Lumi UI] Intensity:", math.floor(value + 0.5))
    end,
})
general:AddDropdown({
    Name = "Mode",
    Values = {"Default", "Smooth", "Precise"},
    Default = "Default",
    Callback = function(value)
        print("[Lumi UI] Mode:", value)
    end,
})
general:AddButton({
    Name = "Run placeholder action",
    Callback = function()
        print("[Lumi UI] Placeholder action executed")
    end,
})

local playerSection = player:AddSection("Player placeholders")
playerSection:AddToggle({Name = "Movement placeholder", Default = false})
playerSection:AddSlider({Name = "Speed placeholder", Min = 1, Max = 10, Default = 4})
playerSection:AddButton({Name = "Reset placeholder"})

local visualSection = visuals:AddSection("Visual placeholders")
visualSection:AddToggle({Name = "Overlay placeholder", Default = false})
visualSection:AddDropdown({Name = "Style", Values = {"Lumi", "Minimal", "Compact"}, Default = "Lumi"})
visualSection:AddButton({Name = "Preview placeholder"})

window:SetDetails(
    "Lumi UI",
    "Premium visual pilot loaded. Use the controls to inspect state and interaction quality.",
    "Pilot ready"
)

print("[Lumi UI] Visual pilot v0.2 loaded")

return Lumi