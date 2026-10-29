local Runtime = require("Runtime")
local UI = require("UI")
local T = require("Theme")
local Tab = require("Tab")
local Motion = require("Motion")
local Inspector = require("components/Inspector")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Window = {}
Window.__index = Window

function Window.new(options)
    local rt = Runtime.new()
    rt.Animations = options.Animations ~= false
    local root = rt:Mount()
    local self = setmetatable({Runtime = rt, Root = root, Tabs = {}, _destroyed = false,
        Width = 1100, Height = 660, Scale = 1, OpenDropdown = nil}, Window)
    local main = UI.frame(root, "Main", 0, 0, 1100, 660, T.Shell, 12)
    main.Active = true
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    self.Main = main
    self.UIScale = UI.new("UIScale", main, {Scale = 1})
    local shadow = UI.frame(main, "Shadow", -6, 5, 1112, 664, Color3.fromRGB(15, 13, 11), 15)
    shadow.BackgroundTransparency = 0.65
    shadow.ZIndex = 0
    self.Shadow = shadow
    UI.stroke(main, T.Line)
    self.TopEdge = UI.frame(main, "TopEdge", 12, 0, 1076, 1, T.Secondary)
    self.TopEdge.BackgroundTransparency = 0.88

    local sidebar = UI.frame(main, "Sidebar", 0, 0, 184, 660, T.Sidebar, 12)
    self.Sidebar = sidebar
    UI.frame(sidebar, "InnerEdge", 174, 0, 10, 660, T.Sidebar)
    local brandTile = UI.frame(sidebar, "BrandTile", 21, 24, 30, 30, T.AccentWash, 7)
    UI.stroke(brandTile, T.AccentSoft).Transparency = 0.65
    UI.mark(brandTile, 5, 5, 20)
    UI.text(sidebar, "Brand", options.Title or "lumi", 60, 21, 110, 30, 25, T.Text, T.Medium)
    UI.text(sidebar, "BrandSub", "INTERFACE LIBRARY", 21, 65, 145, 14, 11, T.Muted, T.Medium)
    UI.line(sidebar, 20, 100, 144)
    UI.text(sidebar, "Group", "WORKSPACE", 22, 122, 140, 16, 10, T.Muted, T.Medium)
    self.Navigation = UI.new("ScrollingFrame", sidebar, {
        Name = "Navigation", Position = UDim2.fromOffset(12, 153), Size = UDim2.new(1, -24, 1, -258),
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.Muted, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    UI.list(self.Navigation, 5)
    local footer = UI.frame(sidebar, "SidebarFooter", 20, 565, 144, 76)
    self.SidebarFooter = footer
    UI.line(footer, 0, 0, 144)
    UI.mark(footer, 0, 20, 22, T.Secondary)
    UI.text(footer, "Build", "Lumi UI", 33, 17, 100, 18, 12, T.Text, T.Medium)
    UI.text(footer, "Version", "Studio / 0.4.4", 33, 38, 110, 16, 11, T.Muted)
    UI.frame(main, "SidebarRule", 183, 0, 1, 660, T.SoftLine)

    local chrome = UI.frame(main, "Chrome", 184, 0, 916, 48)
    self.Chrome = chrome
    local drag = UI.button(chrome, "TitleDrag", "", 0, 0, 862, 48)
    self.Breadcrumb = UI.text(drag, "Breadcrumb", "Workspace  /  Overview", 24, 0, 400, 48, 11, T.Secondary)
    local tag = UI.frame(chrome, "Status", 690, 14, 156, 22)
    UI.frame(tag, "StatusDot", 10, 8, 6, 6, T.Green, 3)
    UI.text(tag, "StatusLabel", options.Status or "LOCAL WORKSPACE", 23, 0, 127, 22, 9, T.Secondary, T.Medium)
    self.StatusTag = tag
    local close = UI.button(chrome, "Close", "", 872, 9, 30, 30)
    UI.corner(close, 5)
    local ca = UI.frame(close, "CloseA", 9, 14, 12, 1, T.Secondary)
    local cb = UI.frame(close, "CloseB", 9, 14, 12, 1, T.Secondary)
    ca.Rotation, cb.Rotation = 45, -45
    UI.hover(rt, close, T.Shell, T.Hover)
    rt:Connect(close.Activated, function() self:Close() end)
    self.CloseButton = close
    UI.line(chrome, 0, 47, 916)

    self.Workspace = UI.frame(main, "Workspace", 184, 48, 696, 584, T.Workspace)
    self.Workspace.ClipsDescendants = true
    self.Context = Inspector.new(self)

    local status = UI.frame(main, "Statusbar", 184, 632, 916, 28, T.Shell)
    self.Statusbar = status
    UI.line(status, 0, 0, 916)
    UI.frame(status, "Dot", 22, 11, 5, 5, T.Green, 3)
    self.StatusText = UI.text(status, "State", "Ready", 35, 0, 560, 28, 10, T.Secondary)
    local version = UI.text(status, "Version", "LUAU  /  LUMI 0.4.4", 730, 0, 160, 28, 11, T.Muted, T.Mono)
    version.TextXAlignment = Enum.TextXAlignment.Right
    self.StatusVersion = version
    self.Blocker = UI.button(root, "PopoverDismiss", "", 0, 0, 0, 0)
    self.Blocker.Size = UDim2.fromScale(1, 1)
    self.Blocker.ZIndex = 90
    self.Blocker.Visible = false
    rt:Connect(self.Blocker.Activated, function() self:ClosePopup(true) end)

    rt:Connect(drag.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        self:ClosePopup()
        local start, origin = input.Position, self.Center
        self:BeginPointer(input, function(position)
            local delta = Vector2.new(position.X - start.X, position.Y - start.Y)
            self:SetCenter(origin + delta)
        end)
    end)
    rt:Connect(Input.InputChanged, function(input)
        if not self._pointer then return end
        if input == self._pointer or (self._pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
            self._pointerUpdate(input.Position)
        end
    end)
    rt:Connect(Input.InputEnded, function(input)
        if input == self._pointer or (input.UserInputType == Enum.UserInputType.MouseButton1 and self._pointer and self._pointer.UserInputType == Enum.UserInputType.MouseButton1) then self:EndPointer() end
    end)
    rt:Connect(Input.WindowFocusReleased, function() self:EndPointer(); self:ClosePopup() end)
    rt:Connect(Input.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.Escape then self:ClosePopup(true); self:EndPointer() end
    end)
    local viewport = UI.new("Frame", root, {Name = "Viewport", Size = UDim2.fromScale(1, 1)})
    self.Viewport = viewport
    self.Motion = Motion.new(rt, main)
    rt:Connect(viewport:GetPropertyChangedSignal("AbsoluteSize"), function() self:Fit() end)
    rt:OnCleanup(function()
        self._destroyed = true
        self:EndPointer()
        self:ClosePopup()
    end)
    self:Fit()
    task.defer(function()
        if self._destroyed or self._closing or self._entranceInterrupted or rt.Animations == false then return end
        self.UIScale.Scale = self.Scale * 0.99
        rt:Tween(self.UIScale, {Scale = self.Scale}, Motion.Time.Open)
        self.Motion:Fade(0.8, 0, Motion.Time.Open)
    end)
    return self
end

function Window:FinishEntrance(interrupt)
    if interrupt ~= false then self._entranceInterrupted = true end
    if self._closing or not self.Motion.Active then return end
    self.Motion:Finish()
    self.Runtime:CancelTween(self.UIScale)
    self.UIScale.Scale = self.Scale
end

function Window:Fit()
    if self._destroyed or self._closing then return end
    local size = self.Viewport.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    if self._lastViewport == size then return end
    local resized = self._lastViewport ~= nil
    self._lastViewport = size
    self:FinishEntrance(resized)
    self:ClosePopup()
    local compact = size.X < 850 or size.Y < 692
    self.Width = compact and math.max(320, math.min(1100, size.X - 32)) or 1100
    self.Height = math.max(280, math.min(660, size.Y - 32))
    self.SidebarWidth = size.X < 700 and 140 or 184
    local sideWidth = self.SidebarWidth
    self.Inspector.Visible = not compact
    self.Main.Size = UDim2.fromOffset(self.Width, self.Height)
    self.TopEdge.Size = UDim2.fromOffset(self.Width - 24, 1)
    self.Shadow.Size = UDim2.fromOffset(self.Width + 12, self.Height + 4)
    self.Sidebar.Size = UDim2.fromOffset(sideWidth, self.Height)
    self.Sidebar.InnerEdge.Position = UDim2.fromOffset(sideWidth - 10, 0)
    self.Sidebar.InnerEdge.Size = UDim2.fromOffset(10, self.Height)
    self.Sidebar.Brand.Size = UDim2.fromOffset(sideWidth - 70, 30)
    self.Sidebar.BrandSub.Size = UDim2.fromOffset(sideWidth - 40, 14)
    self.Sidebar.BrandSub.Text = sideWidth < 170 and "UI LIBRARY" or "INTERFACE LIBRARY"
    local short = self.Height < 480
    local navTop = short and 112 or 153
    self.Sidebar.BrandSub.Position = UDim2.fromOffset(21, short and 60 or 65)
    self.Sidebar.Rule.Position = UDim2.fromOffset(20, short and 80 or 100)
    self.Sidebar.Group.Position = UDim2.fromOffset(22, short and 89 or 122)
    self.Sidebar.Rule.Size = UDim2.fromOffset(sideWidth - 40, 1)
    self.Navigation.Position = UDim2.fromOffset(12, navTop)
    self.Navigation.Size = UDim2.new(1, -24, 1, -(navTop + (short and 80 or 105)))
    self.SidebarFooter.Position = UDim2.fromOffset(20, self.Height - (short and 69 or 95))
    self.SidebarFooter.Size = UDim2.fromOffset(sideWidth - 40, short and 56 or 76)
    self.SidebarFooter.Rule.Size = UDim2.fromOffset(sideWidth - 40, 1)
    self.SidebarFooter.Build.Size = UDim2.fromOffset(sideWidth - 73, 18)
    self.SidebarFooter.Version.Size = UDim2.fromOffset(sideWidth - 73, 16)
    self.Main.SidebarRule.Position = UDim2.fromOffset(sideWidth - 1, 0)
    self.Main.SidebarRule.Size = UDim2.fromOffset(1, self.Height)
    local chromeWidth = self.Width - sideWidth
    self.Chrome.Position = UDim2.fromOffset(sideWidth, 0)
    self.Chrome.Size = UDim2.fromOffset(chromeWidth, 48)
    self.CloseButton.Position = UDim2.fromOffset(chromeWidth - 44, 9)
    self.StatusTag.Position = UDim2.fromOffset(chromeWidth - 226, 14)
    self.StatusTag.Visible = chromeWidth >= 650
    self.Breadcrumb.Size = UDim2.fromOffset(math.max(1, chromeWidth - (self.StatusTag.Visible and 260 or 80)), 48)
    self.Workspace.Position = UDim2.fromOffset(sideWidth, 48)
    self.Workspace.Size = UDim2.fromOffset(chromeWidth - (compact and 0 or 220), self.Height - 76)
    self.Inspector.Position = UDim2.fromOffset(self.Width - 212, 60)
    self.Inspector.Size = UDim2.fromOffset(204, self.Height - 100)
    self.Statusbar.Position = UDim2.fromOffset(sideWidth, self.Height - 28)
    self.Statusbar.Size = UDim2.fromOffset(chromeWidth, 28)
    self.Chrome.Rule.Size = UDim2.fromOffset(chromeWidth, 1)
    self.Statusbar.Rule.Size = UDim2.fromOffset(chromeWidth, 1)
    self.StatusVersion.Position = UDim2.fromOffset(chromeWidth - 186, 0)
    self.StatusVersion.Visible = chromeWidth >= 650
    self.StatusText.Size = UDim2.fromOffset(chromeWidth - (self.StatusVersion.Visible and 240 or 50), 28)
    self.Chrome.TitleDrag.Size = UDim2.fromOffset(chromeWidth - 54, 48)
    self.Scale = math.min(1, math.max(0.1, (size.X - 32) / self.Width), math.max(0.1, (size.Y - 32) / self.Height))
    self.UIScale.Scale = self.Scale
    for _, tab in ipairs(self.Tabs) do tab:Relayout() end
    self:SetCenter(self.Center or size / 2)
end

function Window:SetCenter(center)
    local size = self.Viewport.AbsoluteSize
    local half = Vector2.new(self.Width * self.Scale / 2, self.Height * self.Scale / 2)
    local x = math.clamp(center.X, half.X + 8, math.max(half.X + 8, size.X - half.X - 8))
    local y = math.clamp(center.Y, half.Y + 8, math.max(half.Y + 8, size.Y - half.Y - 8))
    self.Center = Vector2.new(x, y)
    self.Main.Position = UDim2.fromOffset(x, y)
end

function Window:BeginPointer(input, update, finish)
    if self._destroyed or self._closing then return end
    self:FinishEntrance()
    self:EndPointer()
    self._pointer, self._pointerUpdate, self._pointerFinish = input, update, finish
end

function Window:EndPointer()
    local finish = self._pointerFinish
    self._pointer, self._pointerUpdate, self._pointerFinish = nil, nil, nil
    if finish then finish() end
end

function Window:ClosePopup(animated)
    if self._retiringPopup then
        local retiring = self._retiringPopup
        self._retiringPopup = nil
        retiring.Popup:Destroy()
        retiring.Cleanup()
    end
    local popup = self.OpenDropdown
    local cleanup, motion = self._popupCleanup, self._popupMotion
    self.OpenDropdown = nil
    self._popupCleanup, self._popupMotion = nil, nil
    self.PopupOwner = nil
    if self.Blocker then self.Blocker.Visible = false end
    if not popup then return end
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(popup) then GuiService.SelectedObject = nil end
    for _, item in ipairs(popup:GetDescendants()) do
        if item:IsA("GuiButton") then item.Selectable = false; item.Active = false end
    end
    if animated and self.Runtime.Animations ~= false and not self._destroyed and not self._closing and motion then
        -- Remove interaction immediately while its short visual exit finishes.
        local shield = UI.button(popup, "Dismissed", "", 0, 0, 0, 0)
        shield.Size, shield.ZIndex = UDim2.fromScale(1, 1), 150
        shield.Selectable = false
        local retiring = {Popup = popup, Cleanup = cleanup}
        self._retiringPopup = retiring
        motion:Fade(0, 1, Motion.Time.Dismiss, function()
            if self._retiringPopup ~= retiring then return end
            self._retiringPopup = nil
            popup:Destroy()
            cleanup()
        end)
    else
        popup:Destroy()
        if cleanup then cleanup() end
    end
end

Window._closeDropdown = Window.ClosePopup

function Window:Focus(control)
    if self._destroyed or self._closing then return end
    local changed = self.SelectedControl ~= control
    if self.SelectedControl and self.SelectedControl.FocusIndicator then
        self.SelectedControl.FocusIndicator.Visible = false
        self.SelectedControl.SelectionWash.Visible = false
    end
    self.SelectedControl = control
    if control.SelectionWash then control.SelectionWash.Visible = true end
    if control.FocusIndicator then
        control.FocusIndicator.Visible = true
        if changed then
            control.FocusIndicator.Size = UDim2.fromOffset(1, 0)
            self.Runtime:Tween(control.FocusIndicator, {Size = UDim2.new(0, 1, 1, -28)}, 0.12)
        end
    end
    self.Context:Update(control)
    self.StatusText.Text = control.Section.Tab.Name .. " / " .. control.Section.Name .. " / " .. control.Name
end

function Window:SetDetails(title, description, status)
    if self._destroyed then return end
    self.Context:Clear()
    self.DetailTitle.Text, self.DetailDescription.Text = title or "Details", description or ""
    self.DetailValue.Text = status or "Ready"
    self.DetailValue.TextSize = #self.DetailValue.Text > 12 and 15 or 28
end

function Window:AddTab(name, options)
    assert(not self._destroyed, "Window is destroyed")
    return Tab.new(self, name, options or {})
end

function Window:SelectTab(tab)
    if self._destroyed or self._closing or not table.find(self.Tabs, tab) then return end
    if self.ActiveTab then self:FinishEntrance() end
    self:EndPointer()
    self:ClosePopup()
    if self.ActiveTab == tab then return end
    local previous = self.ActiveTab
    self.ActiveTab = tab
    for _, item in ipairs(self.Tabs) do
        item.Motion:Finish()
        self.Runtime:CancelTween(item.Page, "position")
        item.Page.Position = UDim2.fromOffset(0, 0)
        local active = item == tab
        item.Page.Visible = active
        local duration = previous and 0.12 or 0
        item:SetActive(active, duration)
    end
    if previous then
        tab.Page.Position = UDim2.fromOffset(0, 4)
        self.Runtime:Tween(tab.Page, {Position = UDim2.fromOffset(0, 0)}, Motion.Time.Page, "position")
        tab.Motion:Fade(0.35, 0, Motion.Time.Page)
    end
    self.Breadcrumb.Text = "Workspace  /  " .. tab.Name
    if self.SelectedControl and self.SelectedControl.FocusIndicator then
        self.SelectedControl.FocusIndicator.Visible = false
        self.SelectedControl.SelectionWash.Visible = false
    end
    self.SelectedControl = nil
    if tab.Controls[1] then self:Focus(tab.Controls[1]) else self:SetDetails(tab.Name, tab.Description, "Ready") end
end

function Window:Close()
    if self._destroyed or self._closing then return end
    self:FinishEntrance()
    self._closing = true
    self:EndPointer()
    self:ClosePopup()
    local focused = Input:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(self.Root) then focused:ReleaseFocus() end
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(self.Root) then GuiService.SelectedObject = nil end
    if self.Runtime.Animations == false then self:Destroy(); return end
    for _, tab in ipairs(self.Tabs) do
        tab.Motion:Finish()
        self.Runtime:CancelTween(tab.Page, "position")
        tab.Page.Position = UDim2.fromOffset(0, 0)
    end
    local shield = UI.button(self.Main, "ClosingShield", "", 0, 0, 0, 0)
    shield.Size, shield.ZIndex = UDim2.fromScale(1, 1), 200
    shield.Selectable = false
    self.Runtime:Tween(self.UIScale, {Scale = self.Scale * 0.99}, Motion.Time.Close)
    self.Motion:Fade(0, 1, Motion.Time.Close, function() self:Destroy() end)
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self.Runtime:Destroy()
end

return Window
